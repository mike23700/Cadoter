<?php

namespace Database\Seeders;

use App\Models\Faq;
use App\Models\Gift;
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
