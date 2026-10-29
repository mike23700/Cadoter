<?php

namespace Database\Seeders;

use App\Models\Faq;
use App\Models\Gift;
use App\Models\Inspiration;
use App\Models\User;
use App\Models\Wrapping;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Storage;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::updateOrCreate(['email' => env('ADMIN_EMAIL', 'admin@cadoter.com')], [
            'name' => 'Admin CADOTER',
            'phone' => '+225 01 00 00 00 00',
            'password' => env('ADMIN_PASSWORD', 'Admin12345'),
        ]);
        $admin->forceFill(['role' => 'admin'])->save();

        $aicha = User::updateOrCreate(['email' => 'aicha@exemple.com'], [
            'name' => 'Aïcha Koné',
            'phone' => '+225 07 00 00 00 00',
            'password' => 'password123',
        ]);

        $wrappings = [
            ['rose', 'Rosé signature', 'Papier rosé · Ruban magenta', 'emballage-rose.jpg'],
            ['kraft', 'Naturel délicat', 'Papier kraft · Lien en coton', 'emballage-kraft.jpg'],
            ['ciel', 'Ciel de douceur', 'Papier bleu · Ruban ivoire', 'emballage-ciel.jpg'],
        ];
        foreach ($wrappings as $i => [$code, $name, $detail, $img]) {
            Wrapping::updateOrCreate(['code' => $code], [
                'name' => $name, 'detail' => $detail, 'position' => $i, 'price' => 0,
                'image_path' => $this->image($img, 'wrappings'),
            ]);
        }

        $gifts = [
            [
                'name' => 'Le rituel du thé', 'price' => 28000, 'city' => 'Abidjan', 'area' => 'Cocody', 'image' => 'the.jpg',
                'description' => 'Une théière et sa tasse en céramique ivoire pour savourer les petits moments. Une attention douce pour les amoureux du thé.',
                'for_who' => ['Parents', 'Ami(e)s', 'Famille', 'Collègue'], 'occasions' => ['Anniversaire', 'Mariage', 'Dot'], 'category' => 'Maison',
            ],
            [
                'name' => 'Bouquet de douceur', 'price' => 18000, 'city' => 'Abidjan', 'area' => 'Marcory', 'image' => 'bouquet.jpg',
                'description' => 'Un bouquet de fleurs séchées aux tons poudrés, pour une attention durable qui adoucit son intérieur.',
                'for_who' => ['Parents', 'Couple', 'Ami(e)s', 'Famille'], 'occasions' => ['Anniversaire', 'Mariage', 'Naissance', 'Décès · Soutenir un proche'], 'category' => 'Fleurs',
            ],
            [
                'name' => 'Le son nomade', 'price' => 35000, 'city' => 'Abidjan', 'area' => 'Plateau', 'image' => 'enceinte.jpg',
                'description' => 'Une enceinte Bluetooth compacte au tissu vert sauge, pour emporter sa musique partout.',
                'for_who' => ['Enfants', 'Couple', 'Ami(e)s', 'Collègue'], 'occasions' => ['Anniversaire', 'Dot'], 'category' => 'High-tech',
            ],
        ];
        $created = [];
        foreach ($gifts as $g) {
            $img = $g['image'];
            unset($g['image']);
            $created[] = Gift::updateOrCreate(['name' => $g['name']], [
                ...$g, 'is_featured' => true, 'is_active' => true, 'image_path' => $this->image($img, 'gifts'),
            ]);
        }

        if (! $aicha->lists()->exists()) {
            $list = $aicha->lists()->create([
                'title' => 'Mon anniversaire',
                'description' => 'Quelques envies pour mes 30 ans. Votre présence reste le plus beau des cadeaux !',
                'occasion' => 'Anniversaire',
                'code' => 'aicha-anniversaire',
                'event_date' => now()->year.'-10-24',
                'image_path' => $this->image('emballage-rose.jpg', 'lists'),
            ]);
            $list->items()->create(['gift_id' => $created[0]->id]);
            $list->items()->create(['gift_id' => $created[1]->id, 'status' => 'Réservé', 'reserved_by_name' => 'Fatou', 'reserved_at' => now()]);
            $list->items()->create(['gift_id' => $created[2]->id]);
        }

        // FAQ de départ, modifiable dans l'administration
        if (! Faq::exists()) {
            $faqs = [
                ['Comment fonctionne une liste de cadeaux ?', 'Créez une liste, ajoutez-y vos envies puis partagez le lien. Vos proches réservent un cadeau pour éviter les doublons.',
                    'How does a gift list work?', 'Create a list, add your wishes and share the link. Your loved ones reserve a gift so nobody offers the same thing twice.'],
                ['Comment payer ma commande ?', 'Le paiement se fait par Orange Money ou MTN Mobile Money. Nous vous contactons pour confirmer la commande.',
                    'How do I pay for my order?', 'Payment is made with Orange Money or MTN Mobile Money. We contact you to confirm the order.'],
                ['Puis-je vendre mes produits sur CADOTER ?', 'Oui : contactez-nous, nous ouvrons un compte boutique pour que vous publiiez vos produits.',
                    'Can I sell my products on CADOTER?', 'Yes: contact us and we will open a shop account so you can publish your products.'],
            ];
            foreach ($faqs as $i => [$q, $a, $qEn, $aEn]) {
                Faq::create(['question' => $q, 'answer' => $a, 'question_en' => $qEn, 'answer_en' => $aEn, 'position' => $i + 1]);
            }
        }

        // Articles « Inspirations » de départ, modifiables dans l'administration
        if (! Inspiration::exists()) {
            $articles = [
                ['soutenir-un-proche', 'Soutien', 'Support', 3, 'bouquet.jpg',
                    'Soutenir un proche en deuil.', 'Supporting a grieving loved one.',
                    'Des attentions sobres et respectueuses, à son rythme.', 'Simple, respectful gestures, at their own pace.',
                    ["Dans les moments difficiles, les gestes simples comptent : un repas apporté, des fleurs sobres, une présence. Évitez les cadeaux trop festifs.",
                        "Une liste de soutien permet à l'entourage de proposer une aide concrète sans doublon, en respectant le rythme de la famille."],
                    ['In difficult times, simple gestures matter: a meal brought over, understated flowers, being there. Avoid gifts that are too festive.',
                        "A support list lets friends and family offer practical help without duplicates, while respecting the family's pace."]],
                ['noel', 'Noël', 'Christmas', 4, 'article-noel.jpg',
                    'Un Noël plein de petites attentions.', 'A Christmas full of small gestures.',
                    "Organiser les cadeaux en famille sans doublon, c'est possible.", 'Organising family gifts without duplicates is possible.',
                    ["À Noël, les cadeaux se multiplient et les doublons aussi. Une liste partagée permet à chacun de réserver ce qu'il offre, sans gâcher la surprise.",
                        'Choisissez un emballage pour chaque cadeau : rosé, kraft ou bleu ciel, le soin du dernier détail fait toute la différence au pied du sapin.'],
                    ["At Christmas, gifts multiply and so do duplicates. A shared list lets everyone reserve what they're giving, without spoiling the surprise.",
                        'Choose a wrapping for each gift: rosé, kraft or sky blue, care down to the last detail makes all the difference under the tree.']],
                ['merci-maman', 'Fête des mères', "Mother's Day", 5, 'article-maman.jpg',
                    'Lui dire merci, tout simplement.', 'Simply saying thank you.',
                    'Des fleurs, un mot, un moment : les petites attentions qui touchent le plus.', 'Flowers, a note, a moment: the small gestures that touch the most.',
                    ["Un bouquet de fleurs séchées dure des mois et rappelle votre attention à chaque regard. Ajoutez un petit mot manuscrit : c'est souvent ce qu'elle gardera le plus longtemps.",
                        "Pour aller plus loin, demandez un cadeau personnalisé : nous vous accompagnons pour composer une attention qui lui ressemble, jusqu'au choix de l'emballage."],
                    ['A bouquet of dried flowers lasts for months and recalls your thoughtfulness at every glance. Add a handwritten note: it\'s often what she will keep the longest.',
                        "To go further, request a custom gift: we'll help you put together something that suits her, right down to the wrapping."]],
                ['pour-papa', 'Fête des pères', "Father's Day", 4, 'article-papa.jpg',
                    'Pour papa, une attention qui compte.', 'For Dad, a gift that matters.',
                    "Un moment partagé, un objet qui lui ressemble : nos pistes pour lui dire ce qu'il représente pour vous.", 'A shared moment, an object that suits him: our ideas to tell him what he means to you.',
                    ["Les pères ont souvent du mal à dire ce qui leur ferait plaisir. Plutôt que de chercher l'objet parfait, pensez à ce qu'il aime faire : lire le journal au calme, écouter ses vieux disques, recevoir la famille le dimanche.",
                        "Un rituel du thé, une enceinte pour sa musique ou un simple déjeuner partagé : l'important est que le cadeau raconte quelque chose de votre lien.",
                        "Et si vous hésitez, créez une liste avec vos frères et sœurs : chacun choisit, personne n'offre deux fois la même chose."],
                    ['Fathers often find it hard to say what they would like. Rather than looking for the perfect object, think about what he loves doing: reading the paper in peace, listening to his old records, having the family over on Sundays.',
                        'A tea ritual, a speaker for his music or a simple shared lunch: what matters is that the gift says something about your bond.',
                        "And if you're unsure, create a list with your brothers and sisters: everyone chooses, and nobody gives the same thing twice."]],
            ];
            // Créés du plus ancien au plus récent : « Pour papa » reste l'article à la une
            foreach ($articles as $i => [$slug, $tag, $tagEn, $minutes, $file, $title, $titleEn, $excerpt, $excerptEn, $body, $bodyEn]) {
                $article = new Inspiration([
                    'slug' => $slug, 'tag' => $tag, 'tag_en' => $tagEn, 'minutes' => $minutes,
                    'title' => $title, 'title_en' => $titleEn, 'excerpt' => $excerpt, 'excerpt_en' => $excerptEn,
                    'body' => implode("\n\n", $body), 'body_en' => implode("\n\n", $bodyEn),
                ]);
                $article->image_path = $this->image($file, 'inspirations');
                $article->created_at = now()->subMinutes(count($articles) - $i);
                $article->save();
            }
        }
    }

    private function image(string $file, string $dir): string
    {
        $path = "$dir/$file";
        if (! Storage::disk('public')->exists($path)) {
            Storage::disk('public')->put($path, file_get_contents(__DIR__."/images/$file"));
        }

        return $path;
    }
}
