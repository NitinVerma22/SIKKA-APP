# Task List - Real Checkout & Order System

- [x] Database Layer Modifications
  - [x] Modify `2025_11_29_063023_create_orders_table.php`
  - [x] Modify `2025_11_29_063025_create_order_items_table.php`
  - [x] Refresh migrations & seed the database (`php artisan migrate:refresh --seed`)
- [x] Backend Controllers & Services
  - [x] Implement order saving, item creation, and stock reservation in `CheckoutController.php`
  - [x] Implement order listing (`index`) in Admin `OrderController.php`
  - [x] Create `UserOrderController.php` for dashboard order history
- [x] Routing Configuration
  - [x] Add GET routes for admin orders and user orders in `routes/web.php`
- [x] View Templates & UI
  - [x] Create Admin orders list UI in `resources/views/admin/orders/index.blade.php`
  - [x] Create User orders list UI in `resources/views/dashboard/orders.blade.php`
  - [x] Update user dashboard navigation or panel to link to "My Orders"
- [x] Verification & Testing
  - [x] Verify order placement, stock updates, user dashboard, and admin status updates
