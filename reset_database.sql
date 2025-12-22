-- SQL script to reset the database for UUID migration
-- WARNING: This will delete all existing data!

-- Drop all tables
DROP TABLE IF EXISTS sale_items CASCADE;
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS product CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS branch CASCADE;
DROP TABLE IF EXISTS business CASCADE;

-- The tables will be automatically recreated by Hibernate with UUID columns
-- when you restart the application


