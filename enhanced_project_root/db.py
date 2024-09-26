# db.py

import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

DATABASE_URI = os.getenv('DATABASE_URI', 'postgresql+psycopg2://metabolic_user:your_password@localhost:5432/metabolic_db')

engine = create_engine(DATABASE_URI)
Session = sessionmaker(bind=engine)
session = Session()
