
# Walmart Sales Data Analysis

## **Descrição do Projeto**
Este projeto apresenta uma análise de dados de vendas da rede **Walmart**, desenvolvida com **Python (Pandas)**, **SQL Server** e **Power BI**.  
O objetivo foi **comparar o desempenho de faturamento entre 2022 e 2023**, avaliar a **distribuição por categoria e método de pagamento**, e identificar as **filiais com maior crescimento percentual**.  

O fluxo completo envolve:  
1. **Limpeza e transformação dos dados** em Python  
2. **Carregamento e consultas** no SQL Server  
3. **Criação de dashboards interativos** no Power BI  

---

## **Tecnologias Utilizadas**
- **Python 3.10+**
  - Bibliotecas: `pandas`, `sqlalchemy`, `psycopg2`, `pyodbc`, `matplotlib`
- **SQL Server (SQL Express)** – armazenamento e consultas analíticas
- **Power BI Desktop** – visualização e criação de KPIs
- **Dataset:** `Walmart_dataset.csv`

---

## **Etapas do Projeto**

### 1 **Tratamento e Limpeza dos Dados (Python)**
Principais etapas realizadas com `pandas`:
- Leitura do dataset: `pd.read_csv()`
- Verificação e remoção de valores nulos: `.isnull().sum()` e `.dropna()`
- Eliminação de duplicatas: `.drop_duplicates()`
- Padronização de colunas para letras minúsculas
- Conversão de tipos:
  - `quantity` → inteiro  
  - `unit_price` → float (remoção do símbolo `$`)
- Criação da coluna `total_price` = `unit_price * quantity`
- Exportação do dataset tratado:
  ```python
  df.to_csv('Dataset_Walmart_transformed.csv', index=False)

### 2 **Envio do Dataset ao SQL Server**
O dataset tratado foi carregado no SQL Server usando SQLAlchemy:

```
python
from sqlalchemy import create_engine

engine = create_engine(
    "mssql+pyodbc://@localhost\\SQLEXPRESS/wlt?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes"
)

df.to_sql(
    name='Walmart',
    con=engine,
    if_exists='replace',
    index=False
)
```
### 3 **Consultas SQL e Tabelas de Apoio**

Criação de tabelas auxiliares para modelagem e análise no Power BI:

**Tabela Vendas**

```
WITH vendas AS (
    SELECT
        invoice_id,
        category,
        unit_price,
        total_price,
        quantity,
        rating,
        payment_method,
        branch,
        date
    FROM Walmart
)
SELECT *
FROM vendas
WHERE YEAR(CONVERT(DATE, [date], 3)) IN (2022, 2023);
```
**Tabela Data**
```
WITH data AS (
    SELECT 
        CONVERT(DATE, [date], 3) AS data_completa,
        YEAR(CONVERT(DATE, [date], 3)) AS ano_data,
        DATENAME(MONTH, CONVERT(DATE, [date], 3)) AS mes_data,
        DATENAME(WEEKDAY, CONVERT(DATE, [date], 3)) AS dia_data,
        CASE 
            WHEN DATEPART(HOUR, TRY_CONVERT(time, [time])) BETWEEN 6 AND 11 THEN 'Morning'
            WHEN DATEPART(HOUR, TRY_CONVERT(time, [time])) BETWEEN 12 AND 17 THEN 'Afternoon'
            ELSE 'Evening'
        END AS turno
    FROM Walmart
    WHERE YEAR(CONVERT(DATE, [date], 3)) IN (2022, 2023)
)
SELECT * FROM data;
```

**Tabela Filial**

Essas tabelas serviram como base para análises de:

- Faturamento total por ano

- Vendas por categoria e filial

- Padrões de compra por horário e dia da semana

- Modelagem e Visualização (Power BI)

### **4 Modelagem e Visualização (Power BI)**

A modelagem no Power BI envolveu:

- Criação das medidas DAX para KPIs

- Relacionamentos entre tabelas de Data, Vendas e Categoria

- Construção de dashboards comparativos 2022–2023

**Principais Métricas DAX**

```
Diferença_faturamento = [Faturamento_2023] - [Faturamento_2022]

Faturamento_2022 = 
CALCULATE(
    SUM('Venda'[faturamento]),
    'Data'[ano] = 2022
)

Faturamento_2023 = 
CALCULATE(
    SUM('Venda'[faturamento]),
    'Data'[ano] = 2023
)

Variacao_percentual = 
DIVIDE([Diferença_faturamento], [Faturamento_2022])

iconePercentual = 
VAR v = [Variacao_percentual]
RETURN
SWITCH(
    TRUE(),
    v > 0, "🟢 ",
    v < 0, "🔴 ",
    v == 0, "⚪ "
)
```

### **5 Visualização dos KPIs (Power BI)**

O dashboard apresenta:

- Faturamento Anual (2022 vs 2023)

- Variação Percentual (YoY)

- Distribuição por Método de Pagamento

- Ranking de Filiais e Categorias

(Você pode incluir prints ou links do dashboard aqui.)


### Análise do Dashboard de Faturamento 2022-2023

**Principais Resultados**

TABELA 

Crescimento mais acentuado nos meses de outubro a dezembro de 2023, indicando sazonalidade positiva no fim do ano.

**Desempenho e Distribuição**

Faturamento por Método de Pagamento:
 - Cartão de Crédito: $179,11 mil (76,89%)
 - eWallet: $195,86 mil (43,56%)
 - Dinheiro (Cash): $74,69 mil (16,61%)

Observação: a soma dos percentuais deve ser verificada em relação ao total do dataset.

Faturamento por Categoria:
•	Fashion Accessories (Acessórios de Moda) lidera as vendas.
•	Home and Lifestyle e Electronic Accessories seguem em ordem decrescente.
Sazonalidade: crescimento acentuado nos meses de outubro, novembro e dezembro de 2023 em comparação com 2022.

Filiais com Maior Crescimento (2023 vs 2022)

### Conclusão 







