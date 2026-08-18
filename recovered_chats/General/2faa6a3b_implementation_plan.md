# Implementation Plan - Real Checkout & Order System

This plan outlines the changes required to replace the mock order checkout with a fully functional order placement, database persistence, stock reduction, user order tracking, and admin status updates.

## Problem Analysis
1. **Empty Migrations**: The database migrations for `orders` and `order_items` tables only create empty tables with `id` and `timestamps()`. They lack columns like `user_id`, `status`, `total_amount`, `sku`, `price`, etc. This causes order creation to fail.
2. **Mock Checkout**: `CheckoutController::placeOrder` currently just forgets the session cart and redirects without saving anything to the database or updating stock.
3. **Missing Admin View & Routes**: The admin order index view is empty, and there are no `GET` routes to view or list orders.
4. **Missing User Order View**: There is no page for users to view their order history in their dashboard.

---

## Proposed Changes

### Database Layer (Migrations)

#### [MODIFY] [2025_11_29_063023_create_orders_table.php](file:///E:/ddesktop/Office/E-Commerce%20Project/ecommerce/database/migrations/2025_11_29_063023_create_orders_table.php)
Add columns:
- `user_id` (foreign key to `users`, nullable if guest checkout is allowed)
- `status` (string, e.g., 'pending', 'processing', 'completed', 'cancelled', 'delivered')
- `total_amount` (decimal 10,2)
- `name` (string, customer name)
- `mobile` (string, customer phone number)
- `address` (text, customer shipping address)
- `payment_method` (string)
- `payment_status` (string, default 'pending')

#### [MODIFY] [2025_11_29_063025_create_order_items_table.php](file:///E:/ddesktop/Office/E-Commerce%20Project/ecommerce/database/migrations/2025_11_29_063025_create_order_items_table.php)
Add columns:
- `order_id` (foreign key to `orders` cascadeOnDelete)
- `product_id` (foreign key to `products` cascadeOnDelete)
- `sku` (string, nullable)
- `quantity` (integer)
- `price` (decimal 10,2)

---

### Backend Logic

#### [MODIFY] [CheckoutController.php](file:///E:/ddesktop/Office/E-Commerce%20Project/ecommerce/app/Http/Controllers/Frontend/Shop/CheckoutController.php)
Update `placeOrder` method to:
- Validate input fields (name, mobile, address, payment_method).
- Create a new `Order` record in the database using the authenticated user's ID.
- Save each item from the cart (or `buy_now` session) as an `OrderItem` linked to the order.
- Calculate and update the total order amount.
- Trigger `StockService::reserveForOrder($order)` to block the inventory and generate `StockMovement` records.
- Clear the cart sessions and redirect the user to a success page or user dashboard.

#### [MODIFY] [OrderController.php](file:///E:/ddesktop/Office/E-Commerce%20Project/ecommerce/app/Http/Controllers/Admin/OrderController.php)
- Implement `index()` to fetch and paginate all orders with their items for the admin panel view.
- Update `updateStatus` to redirect back with success after performing status transitions and calling `StockService`.

#### [NEW] [UserOrderController.php](file:///E:/ddesktop/Office/E-Commerce%20Project/ecommerce/app/Http/Controllers/UserOrderController.php)
Create a new controller for authenticated users to:
- List their orders: `index()`
- View order details: `show($id)`

---

### Routing & Middleware

#### [MODIFY] [web.php](file:///E:/ddesktop/Office/E-Commerce%20Project/ecommerce/routes/web.php)
- Add GET route for admin orders: `GET /admin/orders` pointing to `OrderController@index`.
- Add GET routes for user orders: `GET /dashboard/orders` pointing to `UserOrderController@index`.

---

### Views & User Interface

#### [MODIFY] [index.blade.php](file:///E:/ddesktop/Office/E-Commerce%20Project/ecommerce/resources/views/admin/orders/index.blade.php)
Build the Admin orders list UI:
- Table listing all orders: ID, Customer Name, Mobile, Total Amount, Order Status, Created Date, Actions.
- A select dropdown in the actions column to change the order status (e.g. pending, processing, delivered, cancelled) submitting to `Route('admin.orders.updateStatus', $order)`.

#### [NEW] [index.blade.php](file:///E:/ddesktop/Office/E-Commerce%20Project/ecommerce/resources/views/dashboard/orders.blade.php)
Build the User dashboard order history UI:
- List of user's orders with item details, total price, status, and purchase date.
- Clean Tailwind CSS style matching the current theme.

---

## Verification Plan

### Automated Steps
1. Run `php artisan migrate:refresh --seed` to clean database tables, execute updated migrations, and populate all categories, products, attributes, variants, and default admin user credentials.
2. Run test script to verify that database tables `orders` and `order_items` have all required columns.

### Manual Verification
1. Log in as a customer, add products/variants to the cart, and proceed to checkout.
2. Place an order and check if:
   - Order and order items are inserted into database.
   - Stock quantities in `product_variants` (or `product_stocks`) are reduced.
   - Stock movements log is created.
3. Access `/dashboard/orders` as the customer and verify order history is listed.
4. Log in as Admin (`admin@example.com` / `password`), go to `/admin/orders`, and update the status of the order to cancelled or delivered, verifying that inventory releases or marks delivered accordingly.
