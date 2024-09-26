# Connect to PostgreSQL as a superuser
psql -U postgres

# In the psql shell, run:
CREATE DATABASE metabolic_db;
CREATE USER metabolic_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE metabolic_db TO metabolic_user;
\q
