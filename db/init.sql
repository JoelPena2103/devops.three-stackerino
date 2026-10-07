-- Creates the table where the backend stores the messages.
-- Run it ONCE:  psql -h localhost -U stackerino -d stackerino -f db/init.sql
CREATE TABLE IF NOT EXISTS messages (
  id         SERIAL PRIMARY KEY,
  author     VARCHAR(50)  NOT NULL,
  text       VARCHAR(280) NOT NULL,
  created_at TIMESTAMP    NOT NULL DEFAULT NOW()
);

INSERT INTO messages (author, text) VALUES ('Teacher', 'Welcome to Three-Stackerino! 🎉');
