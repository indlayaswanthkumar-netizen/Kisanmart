# KisanMart database access matrix

RLS is enabled on every application table in the Phase 1 migration. Policies are
paired with narrower SQL grants: access to a row does not automatically permit
changing protected columns. `admin` means the database-backed `user_roles` row,
checked through `current_user_is_admin()`; browser claims are not trusted.

| Table                 | Anonymous access                         | Farmer access                                                                 | Seller access                                                                               | Admin / trusted operation                                                        |
| --------------------- | ---------------------------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `profiles`            | None                                     | Read own; update name, phone, locale only                                     | Same as farmer                                                                              | Read through admin policy                                                        |
| `user_roles`          | None                                     | Read own roles only                                                           | Same                                                                                        | Role changes only through `admin_grant_role`; signup always creates `farmer`     |
| `addresses`           | None                                     | Manage own addresses                                                          | Same as farmer                                                                              | Authorized support access through policy                                         |
| `sellers`             | Approved public business fields only     | Read own record                                                               | Read and edit permitted business fields on own pending/rejected record; cannot approve self | Status changes through `admin_set_seller_status`                                 |
| `categories`          | Active categories                        | Active categories                                                             | Active categories                                                                           | Manage; RLS blocks non-admin writes                                              |
| `crops`               | Published crop names                     | Published crop names                                                          | Published crop names                                                                        | Manage                                                                           |
| `crop_stages`         | Stages for published crops               | Same                                                                          | Same                                                                                        | Manage                                                                           |
| `products`            | Published product fields only            | Published products                                                            | Read own products; insert draft only as approved seller; edit own unpublished content       | Moderate through `admin_set_product_status`                                      |
| `product_variants`    | Active variants of published products    | Same                                                                          | Manage own variants only while seller is approved                                           | Admin policy                                                                     |
| `inventory`           | None                                     | None                                                                          | Read own product stock                                                                      | Stock writes reserved for future transactional server functions                  |
| `inventory_movements` | None                                     | None                                                                          | Read own product movement history                                                           | Admin policy; no direct client writes                                            |
| `carts`               | None                                     | Manage own cart                                                               | Same as farmer                                                                              | Admin policy                                                                     |
| `cart_items`          | None                                     | Manage items in own cart; only active variants of published products          | Same as farmer                                                                              | Admin policy                                                                     |
| `wishlists`           | None                                     | Manage own wishlist                                                           | Same as farmer                                                                              | Admin policy                                                                     |
| `orders`              | None                                     | Read own orders                                                               | No base order/address access                                                                | Admin policy; creation and totals are server controlled                          |
| `order_items`         | None                                     | Read items in own orders                                                      | Read only line items tied to own seller ID                                                  | Admin policy; no client writes                                                   |
| `payments`            | None                                     | Read safe status/amount fields for own order                                  | None                                                                                        | Trusted server/webhook writes; no browser writes                                 |
| `shipments`           | None                                     | Read own order shipment                                                       | Read shipment rows assigned to own seller                                                   | Admin policy; no client writes                                                   |
| `reviews`             | Published review fields only             | Read published reviews; insert a pending review only for a delivered purchase | Published review fields only                                                                | Moderate through `admin_set_review_status`; rating totals are trigger-maintained |
| `questions`           | Published Q&A fields only                | Read published or own questions; create pending questions                     | Read/answer questions for own products; cannot set moderation status                        | Moderate through `admin_set_question_status`                                     |
| `coupons`             | None                                     | None                                                                          | None                                                                                        | Admin policy; validation/redemption belongs in trusted transactional code        |
| `coupon_redemptions`  | None                                     | Read own redemptions                                                          | None                                                                                        | Admin policy; writes reserved for trusted checkout code                          |
| `crop_products`       | Published mappings to published products | Same                                                                          | Same                                                                                        | Manage                                                                           |
| `blog_posts`          | Published posts                          | Published posts                                                               | Published posts                                                                             | Manage                                                                           |
| `notifications`       | None                                     | Read own; mark own notifications read                                         | Same as farmer                                                                              | Admin policy; creation is server-side                                            |
| `product_assets`      | Approved assets for published products   | Same                                                                          | Manage asset metadata only for own products                                                 | Approval through `admin_set_asset_approval`                                      |
| `seller_documents`    | None                                     | None                                                                          | Upload and read own documents; cannot read another seller’s documents                       | Review status through `admin_set_seller_document_status`; private file access    |
| `audit_logs`          | None                                     | None                                                                          | None                                                                                        | Admin read; trusted functions write                                              |
| `banners`             | Active published banners                 | Same                                                                          | Same                                                                                        | Manage                                                                           |

## Storage

Both buckets are private. `product-images` allows anonymous object reads only
when its object path belongs to an approved asset of a published product.
Uploads and replacement are limited to the approved seller that owns the
product; paths follow `<seller-id>/<product-id>/<file-name>`. `seller-documents`
allows upload/read only for the owning seller and read/delete for verified
admins. Never use public URLs for seller verification files.

## Boundaries and follow-up checks

- Supabase service-role operations bypass RLS and must remain server-only. The
  Phase 1 web app does not require a service-role key.
- Sellers cannot read customer address snapshots from the `orders` table.
  Seller order lines expose only the associated line-item data; a later
  fulfillment workflow must expose only delivery details needed for that sale.
- Order creation, coupon redemption, stock reservation, and payment processing
  are deliberately not enabled by direct client writes. Add transactional,
  idempotent server operations before implementing those later phases.
- The first administrator must be granted manually in the Supabase SQL Editor
  after verifying their Auth user ID. Public signup cannot create or select an
  administrator or seller role.
- Before production, test policies with separate anonymous, farmer, approved
  seller, pending seller, and administrator sessions, including storage paths
  and joins.
