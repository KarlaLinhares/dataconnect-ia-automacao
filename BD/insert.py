import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
import re

caminho_arquivo = r"C:\Users\bruno\Downloads\camada_prata_automotivo.xlsx"

url_banco = URL.create(
    drivername="postgresql+psycopg2",
    username="postgres",
    password="123456",
    host="localhost",
    port=5432,
    database="postgres"
)

engine = create_engine(url_banco)

with engine.begin() as conn:
    conn.execute(text("CREATE SCHEMA IF NOT EXISTS sisauto;"))

arquivo_excel = pd.ExcelFile(caminho_arquivo)

for nome_aba in arquivo_excel.sheet_names:
    if nome_aba.lower() == 'leia-me':
        continue
        
    df = pd.read_excel(caminho_arquivo, sheet_name=nome_aba)
    
    colunas_limpas = []
    for coluna in df.columns:
        nome_coluna = str(coluna).strip().lower()
        nome_coluna = re.sub(r'[^a-z0-9_]', '_', nome_coluna)
        nome_coluna = re.sub(r'_+', '_', nome_coluna)
        nome_coluna = nome_coluna.strip('_')
        if not nome_coluna:
            nome_coluna = "coluna_vazia"
        colunas_limpas.append(nome_coluna)
        
    df.columns = colunas_limpas
    
    nome_tabela = str(nome_aba).strip().lower()
    nome_tabela = re.sub(r'[^a-z0-9_]', '_', nome_tabela)
    nome_tabela = re.sub(r'_+', '_', nome_tabela)
    nome_tabela = nome_tabela.strip('_')
    
    df.to_sql(nome_tabela, engine, schema='sisauto', if_exists='replace', index=False)

engine.dispose()