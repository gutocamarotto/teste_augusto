/*----------------------------------------------------------------------------------------------------------------------------------
															Item 1
-----------------------------------------------------------------------------------------------------------------------------------*/
SELECT COUNT(DISTINCT NOME_CLIENTE) FROM (
SELECT
       ORD.ID_CLIENTE                             AS ID_CLIENTE_FATO,
       CLI.ID_CLIENTE                             AS ID_CLIENTE_DIM,
       CLI.NOME                                   AS NOME_CLIENTE, 
       CLI.DT_NASCIMENTO                          AS DT_NASCIMENTO_CLIENTE,
       COUNT(ORD.ID_ORDER)                        AS QUANTIDADEVENDA
FROM `PROJETO.DATASET.fato_order` ORD
INNER JOIN `PROJETO.DATASET.dim_cliente` CLI
        ON CLI.ID_CLIENTE = ORD.ID_CLIENTE
WHERE 1=1
  AND ORD.PT_DATA BETWEEN '2020-01-01' AND '2020-01-31' ---Filtra período desejado
GROUP BY 1,2,3,4
)
WHERE 1=1
  AND DT_NASCIMENTO_CLIENTE = CURRENT_DATE() 	---Filtra aniversariantes de hoje
  AND QUANTIDADEVENDA > 1500                    ---Filtra QUANTIDADEVENDA > 1500
  AND ID_CLIENTE_DIM <> -1                      ---Descarta possíveis clientes sem identificação na base
ORDER BY 1; 

SELECT DISTINCT NOME_CLIENTE FROM (
SELECT
       ORD.ID_CLIENTE                             AS ID_CLIENTE_FATO,
       CLI.ID_CLIENTE                             AS ID_CLIENTE_DIM,
       CLI.NOME                                   AS NOME_CLIENTE, 
       CLI.DT_NASCIMENTO                          AS DT_NASCIMENTO_CLIENTE,
       COUNT(ORD.ID_ORDER)                        AS QUANTIDADEVENDA
FROM `PROJETO.DATASET.fato_order` ORD
INNER JOIN `PROJETO.DATASET.dim_cliente` CLI
        ON CLI.ID_CLIENTE = ORD.ID_CLIENTE
WHERE 1=1
  AND ORD.PT_DATA BETWEEN '2020-01-01' AND '2020-01-31' ---Filtra período desejado
GROUP BY 1,2,3,4
)
WHERE 1=1
  AND DT_NASCIMENTO_CLIENTE = CURRENT_DATE() 	---Filtra aniversariantes de hoje
  AND QUANTIDADEVENDA > 1500                    ---Filtra QUANTIDADEVENDA > 1500
ORDER BY 1; 

/*----------------------------------------------------------------------------------------------------------------------------------
															Item 2
-----------------------------------------------------------------------------------------------------------------------------------*/
SELECT * FROM (
/*
Agrupamos o Valor de Vendas ($), a Quantiade de Pedidos e a Quantidade de itens por informações do cliente e ano/mês (PT_DATA)
*/
WITH VENDA_COMPETENCIA AS (
SELECT 
  F.ID_CLIENTE                    AS ID_CLIENTE_FATO,
  D.ID_CLIENTE                    AS ID_CLIENTE_DIM,
  D.NOME                          AS NOME_CLIENTE,
  D.SOBRENOME                     AS SOBRENOME_CLIENTE,
  FORMAT_DATE('%Y%m', F.PT_DATA)  AS PT_DATA,
  SUM(F.VLR_VENDA)                AS VALORVENDA,
  SUM(F.QTD_ITENS)                AS QUANTIDADEITENS,
  COUNT(F.ID_ORDER)               AS QUANTIDADEVENDA
FROM PROJETO.DATASET.fato_order F
INNER JOIN PROJETO.DATASET.dim_cliente D
        ON F.ID_CLIENTE = D.ID_CLIENTE
WHERE ID_DATA >= 20200101 
  AND ID_DATA < 20210101
GROUP BY 1, 2, 3, 4, 5
)
/*
Criamos o Rank com base na coluna PT_DATA (que anteriormente formatei para ano/mês) 
e na soma do Valor de Vendas
*/
SELECT 
  PT_DATA,
  NOME_CLIENTE,
  SOBRENOME_CLIENTE,
  SUM(VALORVENDA)                 AS VALORVENDA,
  SUM(QUANTIDADEITENS)            AS QUANTIDADEITENS,
  SUM(QUANTIDADEVENDA)            AS QUANTIDADEVENDA,
  RANK() OVER (PARTITION BY PT_DATA ORDER BY SUM(VALORVENDA) DESC) AS RANK
FROM VENDA_COMPETENCIA
GROUP BY 1, 2, 3
)
WHERE RANK <= 5
ORDER BY 1, 7

/*----------------------------------------------------------------------------------------------------------------------------------
															Item 3
-----------------------------------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE PROCEDURE `PROJETO.DATASET.pr_carrega_fato_estoque`()
BEGIN
/*=================================================================================================
PROPOSITO: CARREGA DADOS DE ESTOQUE
DATA     : 2023-08-05
/*=================================================================================================
                     LIMPEZA DA TABELA FATO_ESTOQUE
===================================================================================================*/
TRUNCATE TABLE `PROJETO.DATASET.fato_estoque`;
/*=================================================================================================
                     INSERIR DADOS NA TABELA FATO_ESTOQUE
===================================================================================================*/
INSERT INTO `PROJETO.DATASET.fato_estoque`
/*
  Trunco e insiro os dados na tabela de estoque todo fim de dia, realizando o cálculo da 
  Quantidade de Itens que estavam disponíveis na DIM menos (-) a
  Quantidade de Itens que foram vendidos na fato no dia de hoje
*/
WITH ESTOQUE AS (
SELECT 
  F.ID_ITEM                    AS ID_ITEM_FATO,
  D.ID_ITEM                    AS ID_ITEM_DIM,
  SUM(QTD_DISPONIVEL)-SUM(F.QTD_ITENS)                
                               AS ESTOQUE_DIARIO
FROM PROJETO.DATASET.fato_order F
INNER JOIN PROJETO.DATASET.dim_item D
        ON F.ID_ITEM = D.ID_ITEM
WHERE F.PT_DATA = CURRENT_DATE
 GROUP BY 1, 2
)
SELECT 
       CURRENT_DATE             AS PT_DATA,
       CAST(SUBSTR(REPLACE(CAST(CURRENT_DATE AS STRING),'-',''),1,8) AS INT64) 
                                AS ID_DATA,
       ID_ITEM_DIM              AS ID_ITEM,
       SUM(ESTOQUE_DIARIO)      AS ESTOQUE_DIARIO
FROM ESTOQUE
GROUP BY 1,2,3;
/*
	Realizo um UPDATE na DIM_ITEM para atualizar a Quantidade de Itens disponíveis
	***Esse UPDATE com certeza será muito custoso pelo tamanho da base, então a melhor forma seria 
	   incluir um JOIN na carga da DIM_ITEM, buscando a quantidade de itens disponíveis atualizada da fato.
*/
  UPDATE PROJETO.DATASET.dim_item D
     SET D.QTD_DISPONIVEL = F.ESTOQUE_DIARIO
  FROM PROJETO.DATASET.fato_estoque F
  WHERE D.ID_ITEM = F.ID_ITEM 
    AND D.FLAG_ATIVO = 1
	AND D.DT_ELIMINACAO IS NULL;
END;