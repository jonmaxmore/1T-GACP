from sqlalchemy import create_engine, MetaData
import os

DB_URL = f"postgresql://{os.getenv('POSTGRES_USER')}:{os.getenv('POSTGRES_PASSWORD')}@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('POSTGRES_DB')}"
engine = create_engine(DB_URL)
metadata = MetaData()

# สร้างตาราง
def init_db():
    metadata.reflect(bind=engine)
    metadata.create_all(bind=engine)
    print("Database initialized successfully!")

if __name__ == "__main__":
    init_db()
