PRAGMA foreign_keys = ON;
CREATE TABLE customers(customer_id INTEGER PRIMARY KEY, acquisition_channel TEXT NOT NULL);
CREATE TABLE sessions(session_id INTEGER PRIMARY KEY, customer_id INTEGER NOT NULL REFERENCES customers, started_at TEXT NOT NULL, device TEXT NOT NULL);
CREATE TABLE events(event_id INTEGER PRIMARY KEY, session_id INTEGER NOT NULL REFERENCES sessions, event_type TEXT NOT NULL CHECK(event_type IN ('product_view','add_to_cart','checkout','purchase')), event_at TEXT NOT NULL);
CREATE TABLE orders(order_id INTEGER PRIMARY KEY, session_id INTEGER NOT NULL UNIQUE REFERENCES sessions, ordered_at TEXT NOT NULL, amount_cents INTEGER NOT NULL CHECK(amount_cents>0), status TEXT NOT NULL CHECK(status IN ('completed','cancelled')));
CREATE INDEX idx_events_session_time ON events(session_id,event_at);
CREATE INDEX idx_orders_time ON orders(ordered_at);
