# CADOTER — À faire / Spécifications backend

## 1. Vision
Cadoté est une application (web + mobile, FR/EN) de listes et de demandes de cadeaux.
Slogan : « Le bonheur d'offrir, tout simplement ».

Un utilisateur crée une liste pour un événement (anniversaire, mariage, naissance, dot, soutien à un proche en deuil), la partage par lien, et ses proches choisissent et offrent un cadeau sans doublon.

## 2. Rôles
- **Créateur de liste** (compte requis) : crée, modifie et partage la liste, gère la disponibilité des cadeaux, reçoit des dépôts Mobile Money.
- **Invité / donateur** : ouvre le lien partagé (code d'accès optionnel), choisit un cadeau, réserve.

## 3. Parcours principal
1. Créateur crée une liste : titre*, description, image (JPG/PNG, 5 Mo max), occasion*.
2. Ajoute des cadeaux : depuis le catalogue ou par lien marchand (aperçu automatique : image, nom, prix).
3. Partage le lien (ex. cadoter.com/l/aicha-anniversaire). Option : verrouiller par code d'accès.
4. Invité ouvre le lien, voit la liste, choisit un cadeau (une personne par cadeau).
5. Paiement par agrégateur Mobile Money (Orange Money, MTN Mobile Money).
6. Un cadeau n'est marqué « réservé / acheté » que lorsque l'achat est validé.
7. Facture générée côté boutique (l'app n'émet pas de facture).

## 4. Stack technique
| Couche | Technologie | Emplacement |
|--------|-------------|-------------|
| Web | React 18 + TypeScript + Vite | `web/cadoter-web/` |
| Mobile | Flutter 3.38 + Dart | `mobile/cadoter/` |
| Backend | Laravel 13 + PHP 8.3 (Docker) | `backend/` |
| Base de données | PostgreSQL 16 (Docker) | — |
| Auth API | Laravel Sanctum (jeton Bearer) | — |
| Paiement | Agrégateur Mobile Money (Orange / MTN) | à brancher |

**Pas d'installation PHP en local** : tout le backend tourne dans Docker.
Ports hôte : **5433** (Postgres) et **8001** (API), car 5432/8000 sont déjà pris par PEKEGNO.

## 5. État d'avancement

### Backend (`backend/`) — fait
- Tables : `users` (+ phone, role, language), `gifts`, `wrappings`, `gift_lists`, `list_items`, `orders`, `custom_requests`, `favorites`, `personal_access_tokens`
- Seeder : compte admin, compte démo Aïcha, 3 cadeaux, 3 emballages, liste « Mon anniversaire »
- API complète (voir `routes/api.php`) : auth, catalogue filtrable, listes, liens marchands (aperçu Open Graph protégé SSRF), réservation (verrou anti-doublon), commandes, cadeau personnalisé, favoris, assistante, admin
- Assistante : suggestions par règles sur le catalogue (même contrat d'API qu'un futur modèle IA)

### Web (`web/cadoter-web/`) — fait, branché sur l'API
- Pages des maquettes : Accueil, Catalogue, Fiche cadeau, Mes listes, Liste partagée `/l/:code`, Assistante IA, Cadeau personnalisé + emballages, Inspirations + articles, Favoris
- Connexion / inscription (mêmes champs que le mobile), menu compte, commande `/commander/:slug`, historique `/commandes`
- **Administration `/admin`** (compte `role=admin`) : tableau de bord, CRUD des cadeaux avec photo, commandes (statuts), demandes personnalisées
- Les cadeaux affichés partout (accueil, catalogue, assistante) viennent de l'admin

### Mobile (`mobile/cadoter/`) — fait, branché sur l'API
- Les 20 écrans des maquettes : Lancement, Langue, Présentation ×3, Connexion, Inscription, Accueil, Catalogue, Fiche cadeau, Mes listes, Création de liste, Liste éditable, Liste partagée proche, Assistante IA, Suggestions IA, Cadeau personnalisé, Choix d'emballage, Blog, Compte
- + Commande, Favoris, Historique. Jeton stocké avec `flutter_secure_storage`

## 6. Lancer le projet

### 6.1 Backend
```bash
cd backend
docker compose up -d                      # Postgres (5433) + API (http://localhost:8001)
docker compose exec backend php artisan migrate:fresh --seed --force
docker compose exec backend php artisan storage:link
```
Comptes de démo : `admin@cadoter.com` / `Admin12345` (admin) · `aicha@exemple.com` / `password123`.
Pour changer le mot de passe admin : `ADMIN_EMAIL` / `ADMIN_PASSWORD` dans `backend/.env`, puis relancer le seeder.

Commandes utiles :
```bash
docker compose logs -f backend
docker compose exec backend php artisan route:list --path=api
docker compose exec backend php artisan tinker
docker compose exec backend composer require <paquet>
docker compose down
```

### 6.2 Web
```bash
cd web/cadoter-web
cp .env.example .env    # VITE_API_URL=http://localhost:8001/api
npm install && npm run dev
```
Administration : http://localhost:5173/admin

### 6.3 Mobile
```bash
cd mobile/cadoter
flutter run                                           # émulateur Android : API sur 10.0.2.2:8001
flutter run --dart-define=API_URL=http://192.168.x.x:8001/api   # téléphone physique (IP du PC)
```

### 6.4 Base de données — tables (créées)
| Table | Colonnes principales |
|-------|----------------------|
| `users` | id, name, email, phone, password, role, language (FR/EN), created_at |
| `gift_lists` | id, title, description, image_url, occasion, owner_id, access_code (optionnel), created_at, updated_at |
| `gifts` | id, list_id, name, description, image_url, price, currency, city, country, shop, category, for_who, occasions, status (Disponible/Réservé/Indisponible), external_url, reserved_by, reserved_at, created_at |
| `reservations` | id, gift_id, user_id, status, created_at |
| `wallets` (cagnotte) | id, user_id, balance, currency |
| `transactions` | id, wallet_id, amount, type, status, created_at |
| `countries_cities` | country, currency, cities[] (JSON ou table séparée) |
| `personal_access_tokens` | Tokens Sanctum (auth API) |

### 6.5 API endpoints (créés — détail dans `backend/routes/api.php`)
**Auth (Sanctum)**
- `POST /api/register` — nom, téléphone, email, mot de passe (8 car. min), CGU
- `POST /api/login` — email ou téléphone
- `POST /api/logout`
- `GET /api/me`

**Listes**
- `GET /api/lists` — mes listes
- `POST /api/lists` — créer (titre, description, image, occasion)
- `GET /api/lists/{id}` — détail (cadeaux, statut)
- `PUT /api/lists/{id}` — modifier titre/description/image
- `DELETE /api/lists/{id}`
- `POST /api/lists/{id}/share` — générer lien public
- `POST /api/lists/{id}/lock` — activer/désactiver code d'accès

**Cadeaux**
- `GET /api/gifts` — catalogue (filtres : nom, budget, ville, catégorie, « pour qui », tri, badge disponible)
- `GET /api/gifts/{id}` — fiche cadeau
- `POST /api/lists/{id}/gifts` — ajouter un cadeau (catalogue ou lien externe avec aperçu auto)
- `PUT /api/gifts/{id}/availability` — changer disponibilité (créateur uniquement)
- `DELETE /api/gifts/{id}` — retirer un cadeau

**Réservation**
- `POST /api/gifts/{id}/reserve` — réserver (une personne par cadeau)
- `POST /api/reservations/{id}/release` — remettre disponible (créateur)

**Paiement / Cagnotte**
- `GET /api/wallet` — solde cagnotte
- `GET /api/transactions` — historique
- Webhook Mobile Money (Orange / MTN) — confirmation paiement

**Assistante IA**
- `POST /api/assistant/suggest` — critères (événement, sexe, âge, lien, budget, infos) → suggestions

**Cadeau personnalisé**
- `POST /api/custom-gift` — nom, téléphone, budget, description, emballage (pas de commande directe)

### 6.6 Règles métier à respecter
- Un cadeau = une seule réservation ; une fois réservé, indisponible pour les autres proches.
- Lien de liste public par défaut, code d'accès optionnel.
- Prix en FCFA ; pays et villes filtr catalogue (JSON multi-pays).
- Prix affichés dans la devise du pays sélectionné.
- Données personnelles minimales ; avertissement : ne pas saisir d'infos sensibles dans l'IA.
- Cadeaux externes (lien) : réservation simple comme les autres.
- Cadeau personnalisé : formulaire uniquement, l'équipe recontacte.
- Livraison et facture : gérées côté boutique (pas de facture émise par l'app).
- Cagnotte Mobile Money : visible par le créateur, sans plafond.

### 6.7 Intégration Front ↔ Backend
- Remplacer les données mock (`src/data.ts` web, modèles Flutter) par des appels API REST.
- Stockage du token Sanctum (localStorage web / SecureStorage Flutter).
- Gestion des réservations en temps réel (polling ou WebSocket optionnel).
- Upload d'images (stockage local ou S3) pour listes et cadeaux.

## 8. Priorités d'implémentation
1. ~~Créer le projet Laravel + fichiers Docker~~ ✅
2. ~~Configurer connexion PostgreSQL via Docker~~ ✅
3. ~~Migrations + seeders~~ ✅
4. ~~API Auth (register/login/me)~~ ✅
5. ~~API Listes (CRUD + partage + code d'accès)~~ ✅
6. ~~API Cadeaux (catalogue + réservation + disponibilité) + admin~~ ✅
7. ~~Connecter le front web~~ ✅
8. ~~Connecter le front mobile Flutter~~ ✅
9. Intégration paiement Mobile Money (webhook Orange / MTN → passer la commande en `payee`) — **à faire**
10. Cagnotte (`wallets`, `transactions`) — **à faire**
11. Mot de passe oublié (email de réinitialisation) — **à faire**
12. Assistante : brancher un vrai modèle IA derrière `POST /api/assistant/suggest` — **à faire**
13. Traduction anglaise des textes (le choix de langue est enregistré) — **à faire**
14. Tests automatisés (Pest côté Laravel) — **à faire**

## 9. Structure du projet
```
/home/mike/Documents/Cadote/
├── A_FAIRE.md
├── backend/                  ← Laravel 13 (fait)
│   ├── docker-compose.yml
│   ├── docker/php/Dockerfile
│   └── ...
├── web/
│   └── cadoter-web/          ← React + Vite + TS (fait)
└── mobile/
    └── cadoter/              ← Flutter (fait)
└── docs/cadote/              ← maquettes Figma exportées (PDF)
```
