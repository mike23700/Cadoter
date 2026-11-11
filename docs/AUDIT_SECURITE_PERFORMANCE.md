# Audit sécurité & performance — CADOTER

_29 octobre 2026 · backend Laravel (`backend/`) + proxy web (`web/cadoter-web/vite.config.ts`)_

Statut : ✅ corrigé et testé · ⚠️ à faire de votre côté (déploiement / décision produit)

---

## 1. Sécurité

### 1.1 ✅ Limites de débit qui partagent un seul compteur (critique)
**Problème.** Tous les `throttle:X,Y` anonymes utilisaient **la même clé par IP**, sur toutes les routes. Exemple : le diagnostic `/client-log` (60/min) consommait le quota du `/login` (10/min), donc un visiteur pouvait se retrouver bloqué à la connexion sans rien avoir fait. De plus, la seule limite de connexion était par IP : un mot de passe pouvait être deviné depuis plusieurs IP.

**Correctif.** Limiteurs nommés dans `app/Providers/AppServiceProvider.php`, chacun avec son propre compteur :

| Limiteur | Routes | Limites |
|---|---|---|
| `auth` | `/login`, `/register` | 10/min par IP **+ 5/min par identifiant visé** |
| `password-reset` | `/forgot-password`, `/reset-password` | 5/min par IP + 5/h par e-mail |
| `password-change` | `PUT /me/password` | 5/min par compte |
| `shared-list` | `GET /l/{code}`, réservation | 60/min par IP + **10 codes d'accès faux/min** |
| `public-write` | commandes, demandes perso, réservations | 20/min + 200/jour |
| `assistant` | `/assistant/suggest` (IA payante) | 20/min + 300/jour |
| `assistant-external` | `/assistant/external` (IA + web payants) | 6/min + 60/jour |
| `client-log` | `/client-log` | 30/min + 1000/jour |
| `link-preview` | `POST /lists/{id}/items` (lecture d'un site tiers) | 20/min |

Test : 5 essais de connexion sur le même compte, puis `429`. `/client-log` continue de répondre `204` de façon indépendante.

### 1.2 ✅ Vraie IP du visiteur derrière le proxy
**Problème.** Derrière Vite, ngrok ou Docker, Laravel voyait l'IP du proxy : **tous les visiteurs partageaient la même limite**.
**Correctif.**
- `bootstrap/app.php` : `trustProxies` sur les plages privées et loopback (modifiable avec la variable `TRUSTED_PROXIES`).
- `vite.config.ts` : `xfwd: true` sur `/api`, `/storage` et `/l/…`.

### 1.3 ✅ Code d'accès des listes protégées devinable
**Problème.** `GET /l/{code}` n'avait aucune limite : un code de 4 chiffres se trouvait en quelques minutes. La comparaison n'était pas non plus à temps constant.
**Correctif.** Limiteur `shared-list`, plus `hash_equals()` dans `SharedListController::open()`. Un code envoyé sous forme de tableau est refusé.
Test : 10 mauvais codes, puis `429`.

### 1.4 ✅ SSRF dans l'aperçu des liens marchands (`LinkPreview`)
**Problème.** La vérification faisait `gethostbyname()` (IPv4 seulement), puis une **seconde** résolution DNS au moment de la requête. Un DNS « rebinding » pouvait donc viser le réseau interne (Postgres, métadonnées cloud…). Les ports et les identifiants dans l'URL n'étaient pas filtrés, et la taille de réponse n'avait pas de limite.
**Correctif.**
- Toutes les IP du nom (A et AAAA) doivent être publiques. Les plages CGNAT, IPv4-mappées, NAT64 et ULA sont refusées.
- Connexion **épinglée** sur l'IP vérifiée (`CURLOPT_RESOLVE`).
- Ports 80 et 443 seulement, pas de `user:pass@`.
- Pages de plus de 3 Mo abandonnées.
- `og:image` limitée à `http(s)://`.

Tests : `127.0.0.1`, `localhost`, `169.254.169.254`, `[::1]`, `[::ffff:127.0.0.1]`, `100.64.x`, `:8080`, `postgres` sont tous refusés. `example.com` et `jumia.ci` sont lus correctement, en requête simple comme en parallèle.

### 1.5 ✅ Liens externes des listes
`url` est maintenant validé en `url:http,https`. Avant, `data://…` était accepté puis affiché en `href` sur la page partagée.

### 1.6 ✅ Falsification du domaine dans l'aperçu Open Graph
**Problème.** `/apercu/l/{code}` reprenait tel quel `X-Forwarded-Host` dans `og:url` et dans la redirection `meta refresh`. Cela permettait une redirection vers un site pirate, ou un empoisonnement de cache.
**Correctif.** Seuls sont acceptés l'hôte de `FRONTEND_URL`, `localhost` et `*.ngrok(-free).app|dev|io`. Tout autre hôte renvoie vers `FRONTEND_URL`.
Test : `evil.com` et `x.ngrok-free.app.evil.com` renvoient vers `FRONTEND_URL`. `abc.ngrok-free.app` est conservé.

### 1.7 ✅ `role` modifiable en masse (défense en profondeur)
`role` est retiré du `#[Fillable]` de `User`. Un futur `User::create($request->all())` ne permettra plus de devenir admin. La création de boutique (`PartnerController::store`) utilise `forceFill`, et le test confirme que le rôle `partner` est bien enregistré.

### 1.8 ✅ Jetons API sans expiration
`config/sanctum.php` : expiration à 90 jours par défaut (variable `SANCTUM_EXPIRATION`). Purge quotidienne avec `sanctum:prune-expired` dans `routes/console.php`.
> ⚠️ Les utilisateurs mobiles devront se reconnecter au bout de 90 jours. Augmentez la valeur si ce n'est pas voulu.

### 1.9 ✅ En-têtes de sécurité
Nouveau middleware `app/Http/Middleware/SecurityHeaders.php` :
- `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy`, `Permissions-Policy` ;
- CSP `default-src 'none'` sur `/api/*` ;
- HSTS en HTTPS.

### 1.10 ✅ Validation des commandes
- `customer_email` est limité à 190 caractères (avant, une erreur 500 au-delà de 255).
- Les emballages **désactivés** ne peuvent plus être commandés.
- Le budget d'une demande personnalisée est plafonné.

### 1.11 ✅ Paramètres envoyés en tableau
`?city[]=x`, `?q[]=…` et `?status[]=…` provoquaient des erreurs 500 dans le catalogue et l'administration. Ils sont maintenant ignorés.

---

## 2. Logique métier

### 2.1 ✅ Stock jamais rendu à l'annulation
Une commande `en_attente` décrémente le stock. Si l'admin l'annulait, le stock restait perdu. Désormais, `annulee` rend le stock, et le retour depuis `annulee` le reprend. Les deux sont faits dans une transaction avec verrou.
Test : stock 10, commande ×3 → 7, annulation → 10, rétablissement → 7.

### 2.2 ⚠️ Blocage du stock par fausses commandes
N'importe qui peut passer des commandes non payées (jusqu'à 20 articles chacune) et vider le stock d'un cadeau. La limite `public-write` (200/jour/IP) rend l'attaque plus difficile, mais le vrai correctif est un choix produit. Deux options :
- ne décrémenter le stock **qu'au paiement** ;
- annuler automatiquement les commandes `en_attente` après X heures.

---

## 3. Performance

### 3.1 ✅ Index manquants (PostgreSQL)
PostgreSQL **n'indexe pas** les clés étrangères créées par `foreignId()->constrained()`. Toutes les jointures et tous les `where` sur ces colonnes parcouraient donc la table entière.
Migration `2026_10_29_100000_add_performance_indexes.php` (déjà exécutée) :
- `gift_lists.owner_id`
- `list_items.gift_list_id`, `gift_id`, `reserved_by_user_id`
- `orders.user_id`, `gift_id`, `list_item_id`, `(status, created_at)`
- `custom_requests.user_id`, `status`
- `favorites.gift_id`
- `gifts.partner_id`, `(is_active, is_featured, created_at)`
- `important_dates.user_id`
- `users.role`

### 3.2 ✅ Requêtes N+1
- `Gift::seller_name` charge `partner` à chaque cadeau sérialisé. Ce lien est maintenant préchargé dans :
  - la liste partagée (`SharedListController`) ;
  - l'aperçu Open Graph ;
  - les suggestions des rappels e-mail.
- `GET /lists` : une requête par liste pour charger le propriétaire, qui est l'utilisateur courant. C'est remplacé par `setRelation`.

### 3.3 ✅ Fichiers orphelins
- Changer la photo d'une liste supprime désormais l'ancienne.
- Supprimer une liste supprime aussi sa photo.

---

## 4. ⚠️ À faire avant la mise en production

1. **`.env` de prod** : `APP_ENV=production`, `APP_DEBUG=false`, `LOG_LEVEL=warning`. Avec `APP_DEBUG=true`, les traces d'erreur affichent le code et les variables.
2. **`php artisan serve` ne convient pas à la prod.** Utilisez nginx + php-fpm, avec `X-Content-Type-Options: nosniff` sur `/storage` pour les images envoyées par les utilisateurs.
3. **`TRUSTED_PROXIES`** : en prod, mettez seulement l'IP du répartiteur de charge.
4. **`FRONTEND_URL`** : mettez le vrai domaine. Il sert aux e-mails de réinitialisation et à l'aperçu Open Graph.
5. **Mot de passe Postgres** `cadoter_pass` (dans `docker-compose.yml`) et port 5433 exposé : à changer et à fermer en prod.
6. **`/client-log`** : endpoint de diagnostic temporaire. À retirer quand le problème de page blanche sera résolu.
7. **Jeton dans `localStorage`** (web) : il reste exposé en cas de faille XSS. Aucune faille XSS n'a été trouvée (pas de `dangerouslySetInnerHTML`, liens limités à http(s)). Un passage en cookie `HttpOnly` serait une évolution plus lourde.
8. **CORS** : la configuration par défaut de Laravel autorise toutes les origines (`*`). C'est sans danger avec des jetons Bearer sans cookies, mais vous pouvez la restreindre au domaine du site.

## 5. Vérifié, rien à corriger
- Chaque liste, élément, date importante et cadeau partenaire est bien vérifié contre son propriétaire.
- Les routes `/admin` sont protégées, et un admin ne peut pas se retirer ses propres droits.
- Les envois de fichiers sont limités aux formats `jpg/png/webp` avec un nom aléatoire (pas de SVG ni de PHP).
- La réinitialisation du mot de passe donne la même réponse que le compte existe ou non, et déconnecte toutes les sessions.
- Pas d'injection SQL : requêtes paramétrées, `to_tsquery` construit à partir de mots filtrés.
- Réservations et commandes protégées contre les doublons par `lockForUpdate`.
- Les URL des produits externes trouvés par l'IA sont limitées aux domaines autorisés et à celles réellement renvoyées par le moteur de recherche.

## Fichiers modifiés
`app/Providers/AppServiceProvider.php`, `routes/api.php`, `routes/console.php`, `bootstrap/app.php`, `config/sanctum.php`, `app/Http/Middleware/SecurityHeaders.php` (nouveau), `app/Services/LinkPreview.php`, `app/Services/ImportantDateGiftSuggestions.php`, `app/Models/User.php`, contrôleurs `ListController`, `SharedListController`, `OrderController`, `CatalogController`, `Web/SharePreviewController`, `Admin/{Order,Partner,User,Gift}Controller`, migration `2026_10_29_100000_add_performance_indexes.php`, `web/cadoter-web/vite.config.ts`.

> Le serveur Vite doit être **redémarré** pour prendre en compte `xfwd`. Les conteneurs backend, queue et scheduler ont déjà été redémarrés.
