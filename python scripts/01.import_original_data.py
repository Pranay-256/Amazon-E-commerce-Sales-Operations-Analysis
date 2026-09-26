import os
import pandas as pd
from sqlalchemy import create_engine


engine = create_engine("sqlite:///amazon.db")


def ingest_db (df, table_name, engine):
    df.to_sql(table_name, con = engine, if_exists = 'replace', index = False)


def load_original_csv():
    for file in os.listdir('data'):
        if '.csv' in file :
            df = pd.read_csv('data/'+ file)
            ingest_db(df, file[:-4], engine)


if __name__ == '__main__':
    load_original_csv()
    print("Data ingestion completed successfully.")