INSERT INTO products (id, name, description, price, image_url, stock, category) VALUES
    (1, 'Aurora Wireless Headphones', 'Over-ear noise-cancelling headphones with 40-hour battery life.', 129.99, 'https://picsum.photos/seed/headphones/600/400', 42, 'audio'),
    (2, 'Nimbus Mechanical Keyboard', 'Hot-swappable 75% mechanical keyboard with RGB backlight.', 89.50, 'https://picsum.photos/seed/keyboard/600/400', 18, 'peripherals'),
    (3, 'Pulse Ergonomic Mouse', 'Sculpted ergonomic mouse with silent switches and USB-C charging.', 34.99, 'https://picsum.photos/seed/mouse/600/400', 65, 'peripherals'),
    (4, 'Lumen 4K Monitor', '27-inch 4K IPS monitor with 99% sRGB and USB-C power delivery.', 349.00, 'https://picsum.photos/seed/monitor/600/400', 12, 'displays'),
    (5, 'Orbit Portable SSD', '1TB rugged portable SSD with 1050 MB/s read speeds.', 109.00, 'https://picsum.photos/seed/ssd/600/400', 30, 'storage'),
    (6, 'Cascade Bluetooth Speaker', 'Waterproof portable speaker with 24-hour playtime.', 59.99, 'https://picsum.photos/seed/speaker/600/400', 54, 'audio'),
    (7, 'Vertex Laptop Stand', 'Aluminium adjustable laptop stand with cable management.', 45.00, 'https://picsum.photos/seed/stand/600/400', 23, 'accessories'),
    (8, 'Halo Ring Light', 'Dimmable 10-inch ring light with adjustable colour temperature.', 39.95, 'https://picsum.photos/seed/light/600/400', 0, 'accessories')
ON CONFLICT (id) DO NOTHING;