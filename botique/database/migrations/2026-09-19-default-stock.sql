-- Give every product at least 1 unit of stock so newly-added products
-- don't appear as "Out of stock" in the admin panel.

-- 1. Update existing variants that have 0 stock to stock 1
UPDATE product_variants SET stock_qty = 1 WHERE stock_qty = 0;

-- 2. For products that have no variants at all, add a default variant
INSERT INTO product_variants (id, product_id, sku, size, stock_qty)
SELECT gen_random_uuid(), p.id, p.slug || '-default', 'Default', 1
FROM products p
WHERE NOT EXISTS (
  SELECT 1 FROM product_variants v WHERE v.product_id = p.id
);
