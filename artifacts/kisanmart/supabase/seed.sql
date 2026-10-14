-- Development-only, repeatable taxonomy seed data.
-- These names and crop stages are illustrative and are not agronomic advice.
-- Do not run this seed against production.

insert into public.categories (name, slug, description, sort_order)
values
  ('Seeds', 'seeds', 'Illustrative category for seed products.', 10),
  ('Fertilizers and soil care', 'fertilizers-soil-care', 'Illustrative category for plant nutrition and soil-care inputs.', 20),
  ('Crop protection', 'crop-protection', 'Illustrative category; product labels and local rules always apply.', 30),
  ('Irrigation', 'irrigation', 'Illustrative category for irrigation equipment and fittings.', 40),
  ('Farm tools', 'farm-tools', 'Illustrative category for everyday field tools.', 50),
  ('Sprayers', 'sprayers', 'Illustrative category for application equipment.', 60),
  ('Animal feed', 'animal-feed', 'Illustrative category for livestock feed.', 70),
  ('Organic inputs', 'organic-inputs', 'Illustrative category for organic farming inputs.', 80)
on conflict (slug) do nothing;

insert into public.crops (name, slug, description, is_published)
values
  ('Rice (paddy)', 'rice-paddy', 'Illustrative development crop taxonomy only.', true),
  ('Cotton', 'cotton', 'Illustrative development crop taxonomy only.', true),
  ('Groundnut', 'groundnut', 'Illustrative development crop taxonomy only.', true),
  ('Maize', 'maize', 'Illustrative development crop taxonomy only.', true),
  ('Chilli', 'chilli', 'Illustrative development crop taxonomy only.', true),
  ('Tomato', 'tomato', 'Illustrative development crop taxonomy only.', true)
on conflict (slug) do nothing;

insert into public.crop_stages (crop_id, name, sequence, description)
select c.id, stage.name, stage.sequence, 'General illustrative growth-stage label; not a treatment or timing recommendation.'
from public.crops c
cross join (
  values
    ('Establishment', 1),
    ('Vegetative growth', 2),
    ('Flowering or reproductive growth', 3),
    ('Maturity and harvest', 4)
) as stage(name, sequence)
where c.slug in ('rice-paddy', 'cotton', 'groundnut', 'maize', 'chilli', 'tomato')
on conflict (crop_id, sequence) do nothing;
