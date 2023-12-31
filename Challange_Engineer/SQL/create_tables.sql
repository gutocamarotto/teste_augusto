CREATE TABLE `PROJETO.DATASET.dim_cliente`
(
  ID_CLIENTE INT64,
  CPF INT64,
  NOME STRING,  
  SOBRENOME STRING,
  EMAIL STRING,
  GENERO STRING,
  ENDERECO STRING,
  DT_NASCIMENTO DATE,
  ID_DT_NASCIMENTO INT64,
  TELEFONE STRING
);

CREATE TABLE `PROJETO.DATASET.dim_item`
(
  ID_ITEM INT64,
  SKU STRING,
  DESCRICAO_ITEM STRING,
  CATEGORIA STRING,
  FLAG_ATIVO STRING,
  DT_ELIMINACAO DATE,
  QTD_DISPONIVEL FLOAT64,
  PRECO FLOAT64
);

CREATE TABLE `PROJETO.DATASET.dim_categoria`
(
  ID_CATEGORIA INT64,
  CATEGORIA STRING
);

CREATE TABLE `PROJETO.DATASET.dim_data`
(
  ID_DATA INT64,	
  PT_DATA DATE,
  ANO INT64,
  MES INT64,	
  DIA INT64,	
  ANO_MES INT64,	
  MES_NOME	STRING,
  DIA_SEMANA INT64,
  SEMANA_ANO INT64
);


CREATE TABLE `PROJETO.DATASET.fato_order`
(
  PT_DATA DATE,
  ID_DATA INT64,
  ID_ORDER INT64,
  ID_ITEM INT64,
  ID_CLIENTE INT64,
  ID_CATEGORIA INT64,
  QTD_ITENS INT64,
  VLR_VENDA FLOAT64
)
PARTITION BY PT_DATA
CLUSTER BY ID_DATA, ID_ORDER, ID_ITEM, ID_CLIENTE
OPTIONS(
  labels=[("namespace", "DATASET"), ("project", "PROJETO"), ("table", "fato_order")]
);

CREATE TABLE `PROJETO.DATASET.fato_estoque`
(
  PT_DATA DATE,
  ID_DATA INT64,
  ID_ITEM INT64,	
  ESTOQUE_DIARIO FLOAT64
)
PARTITION BY PT_DATA
CLUSTER BY ID_DATA, ID_ORDER, ID_ITEM, ID_CLIENTE
OPTIONS(
  labels=[("namespace", "DATASET"), ("project", "PROJETO"), ("table", "fato_estoque")]
);

