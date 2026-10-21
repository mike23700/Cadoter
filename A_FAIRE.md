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
| Backend | Laravel 13 + PHP 8.3 (Docker) | `backend/` (à créer) |
| Base de données | PostgreSQL 16 (Docker) | — |
| Auth API | Laravel Sanctum | — |
| Paiement | Agrégateur Mobile Money (Orange / MTN) | — |

**Pas d'installation PHP en local** : tout le backend tourne dans Docker (idem projet PEKEGNO).

## 5. Fonctionnalités déjà implémentées (Front)
### Web (React)
- Design system calqué sur la maquette Figma (magenta `#C90091`, crème `#FAF7F2`, Inter / DM Serif Display)
- Routes : `/`, `/cadeaux`, `/cadeaux/:id`, `/listes`, `/l/:code`, `/assistante`, `/personnalise`, `/inspirations`, `/compte`
- Pages : Home, Catalog, GiftPage, Lists, Shared (liste protégée par code), Assistant, Custom, Inspirations, Account
- Store React : gestion des réservations (un cadeau = un seul réservateur)
- Données mock dans `src/data.ts` (à remplacer par l'API)

### Mobile (Flutter)
- Thème `AppTheme` (couleurs maquette)
- Écrans : Splash, Language, Onboarding ×3, Login, Signup, Home, Catalogue, Fiche cadeau, Mes listes, Créer une liste, Compte, Assistante IA, Cadeau personnalisé, Choix d'emballage, Blog
- Navigation bottom : 5 onglets (Accueil / Cadeaux / Mes listes / Assistante / Compte)
- Modèles : `Gift`, `GiftList`

## 6. À faire côté Backend (Laravel + Docker)

### 6.1 Fichiers Docker à créer (modèle PEKEGNO)

**`docker-compose.yml`** (à la racine `backend/`)
```yaml
services:
  postgres:
    image: postgres:16
    container_name: cadotere-postgres
    restart: always
    environment:
      POSTGRES_DB: cadotere
      POSTGRES_USER: cadotere
      POSTGRES_PASSWORD: cadotere_pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  backend:
    build:
      context: ./docker/php
    image: cadotere-php
    container_name: cadotere-backend
    working_dir: /var/www
    volumes:
      - ./backend:/var/www
    ports:
      - "8000:8000"
    depends_on:
      - postgres
    command: php artisan serve --host=0.0.0.0 --port=8000

volumes:
  postgres_data:
```

**`docker/php/Dockerfile`**
```dockerfile
FROM php:8.3-cli

RUN apt-get update && apt-get install -y \
    libpq-dev \
    libzip-dev \
    unzip \
    && docker-php-ext-install pdo_pgsql zip

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /app
```

### 6.2 Installation et démarrage (sans PHP en local)
```bash
# 1. Créer le projet Laravel
composer create-project laravel/laravel backend
cd backend

# 2. Créer les dossiers Docker
mkdir -p docker/php

# 3. Copier docker-compose.yml + docker/php/Dockerfile (voir §6.1)

# 4. Configurer .env (DB_CONNECTION=pgsql, DB_HOST=localhost, DB_PORT=5432, DB_DATABASE=cadotere, DB_USERNAME=cadotere, DB_PASSWORD=cadotere_pass)

# 5. Créer la base PostgreSQL
sudo docker run --rm --network=host postgres:16 \
  psql -h localhost -U postgres -c "CREATE DATABASE cadotere;"
sudo docker run --rm --network=host postgres:16 \
  psql -h localhost -U postgres -c "CREATE USER cadotere WITH PASSWORD 'cadotere_pass';"
sudo docker run --rm --network=host postgres:16 \
  psql -h localhost -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE cadotere TO cadotere;"

# 6. Builder l'image PHP et installer les dépendances
sudo docker build -t cadotere-php docker/php/
sudo docker run --rm -v "$PWD":/app -w /app --network=host \
  cadotere-php composer install --no-interaction

# 7. Générer la clé, lancer migrations et seeders
sudo docker run --rm -v "$PWD":/app -w /app --network=host \
  cadotere-php php artisan key:generate
sudo docker run --rm -v "$PWD":/app -w /app --network=host \
  cadotere-php php artisan migrate --force
sudo docker run --rm -v "$PWD":/app -w /app --network=host \
  cadotere-php php artisan db:seed --force

# 8. Démarrer le serveur
sudo docker compose up -d
```

### 6.3 Commandes utiles (Docker)
```bash
# Voir les logs du backend
sudo docker logs -f cadotere-backend

# Voir les logs de Postgres
sudo docker logs -f cadotere-postgres

# Artisan (migrate, seed, route:list, tinker...)
sudo docker run --rm -v "$PWD":/app -w /app --network=host \
  cadotere-php php artisan migrate:fresh --seed --force
sudo docker run --rm -v "$PWD":/app -w /app --network=host \
  cadotere-php php artisan route:list
sudo docker run --rm -it -v "$PWD":/app -w /app --network=host \
  cadotere-php php artisan tinker

# Arrêter
sudo docker compose down
```

### 6.4 Base de données — tables nécessaires
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

### 6.5 API endpoints à créer
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
1. Créer le projet Laravel + fichiers Docker (docker-compose.yml, docker/php/Dockerfile)
2. Configurer connexion PostgreSQL via Docker
3. Migrations + seeders (tables ci-dessus)
4. API Auth (register/login/me)
5. API Listes (CRUD + partage + code d'accès)
6. API Cadeaux (catalogue + réservation + disponibilité)
7. Connecter le front web
8. Connecter le front mobile Flutter
9. Intégration paiement Mobile Money
10. Facturation côté boutique

## 9. Structure du projet
```
/home/mike/Documents/Cadote/
├── A_FAIRE.md
├── backend/                  ← Laravel (à créer)
│   ├── docker-compose.yml
│   ├── docker/php/Dockerfile
│   └── ...
├── web/
│   └── cadoter-web/          ← React + Vite + TS (fait)
└── mobile/
    └── cadoter/              ← Flutter (fait)
```
