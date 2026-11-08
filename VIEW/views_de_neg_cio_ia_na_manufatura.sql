-- ====================================================================================
-- Q1: Quais tipos de aplicação de IA predominam na manufatura brasileira, 
-- e em qual porte de empresa a adoção está mais atrasada em relação à média do setor?
-- ====================================================================================
CREATE OR REPLACE VIEW sisauto.vw_q1_aplicacoes_ia_porte AS
WITH setor_manufatura AS (
    -- Captura a média de adoção por tipo de aplicação para a Indústria de Transformação
    SELECT 
        edicao AS ano, 
        coluna AS tipo_aplicacao, 
        valor_pct AS pct_industria
    FROM sisauto."3b_tic_long"
    WHERE indicador = 'EMPRESAS QUE UTILIZARAM TECNOLOGIAS DE INTELIGÊNCIA ARTIFICIAL, POR TIPO DE APLICAÇÃO'
      AND recorte_tipo = 'MERCADOS DE ATUAÇÃO'
      AND recorte = 'Indústria de transformação'
),
portes_manufatura AS (
    -- Captura a adoção por porte de empresa (geral)
    SELECT 
        edicao AS ano, 
        coluna AS tipo_aplicacao, 
        recorte AS porte, 
        valor_pct AS pct_porte
    FROM sisauto."3b_tic_long"
    WHERE indicador = 'EMPRESAS QUE UTILIZARAM TECNOLOGIAS DE INTELIGÊNCIA ARTIFICIAL, POR TIPO DE APLICAÇÃO'
      AND recorte_tipo = 'PORTE CADASTRO'
)
SELECT
    s.ano,
    s.tipo_aplicacao,
    s.pct_industria,
    p.porte,
    p.pct_porte,
    -- Calcula o gap: Negativo significa que o porte está atrasado em relação à média da indústria
    ROUND(CAST(p.pct_porte - s.pct_industria AS numeric), 2) AS gap_porte_vs_media_setor_pp
FROM setor_manufatura s
JOIN portes_manufatura p 
  ON s.ano = p.ano AND s.tipo_aplicacao = p.tipo_aplicacao
ORDER BY 
    s.ano DESC, 
    s.pct_industria DESC, 
    p.pct_porte ASC;


-- ====================================================================================
-- Q2: Qual o gap de adoção de IA entre a manufatura brasileira e a média dos países 
-- de renda média-alta nos últimos 3 anos, e o gap está crescendo ou diminuindo?
-- ====================================================================================
CREATE OR REPLACE VIEW sisauto.vw_q2_gap_ia_trajetoria AS
SELECT
    ano,
    brasil_pct_ia_manufatura,
    mediana_pares_pct AS pares_renda_media_alta_pct,
    gap_brasil_vs_mediana_pares_pp,
    -- Calcula a variação do gap em relação ao ano anterior para ver a trajetória
    ROUND(CAST(
        gap_brasil_vs_mediana_pares_pp - LAG(gap_brasil_vs_mediana_pares_pp) OVER (ORDER BY ano ASC) 
    AS numeric), 2) AS variacao_gap_pp,
    CASE
        WHEN (gap_brasil_vs_mediana_pares_pp - LAG(gap_brasil_vs_mediana_pares_pp) OVER (ORDER BY ano ASC)) < 0 
             THEN 'Atraso Crescendo (Piorando)'
        WHEN (gap_brasil_vs_mediana_pares_pp - LAG(gap_brasil_vs_mediana_pares_pp) OVER (ORDER BY ano ASC)) > 0 
             THEN 'Atraso Diminuindo (Melhorando)'
        ELSE 'Sem base de comparação anterior'
    END AS trajetoria_gap
FROM sisauto."2_ocde_gap_ia"
ORDER BY ano DESC;


-- ====================================================================================
-- Q3 PARTE A: Quais funções da manufatura brasileira estão em maior risco de automação?
-- (Responde a: Quem requalificar)
-- ====================================================================================
CREATE OR REPLACE VIEW sisauto.vw_q3a_risco_automacao_funcoes AS
SELECT
    isco08 AS codigo_ocupacao,
    titulo AS funcao_fabril,
    grande_grupo,
    score_2025_medio AS risco_automacao_score,
    classe_exposicao_2025 AS classe_de_risco,
    rank_exposicao_entre_fabris AS ranking_risco
FROM sisauto."6_oit_fabris"
WHERE funcao_fabril = true
ORDER BY score_2025_medio DESC;


-- ====================================================================================
-- Q3 PARTE B: Quais estão emergindo como novas demandas na manufatura?
-- (Responde a: Novas capacidades a contratar/desenvolver)
-- ====================================================================================
CREATE OR REPLACE VIEW sisauto.vw_q3b_novas_demandas_cargos_ia AS
SELECT
    edicao AS ano,
    SPLIT_PART(coluna, ' | ', 1) AS cargo_ia_emergente,
    valor_pct AS pct_empresas_industria_com_cargo
FROM sisauto."3b_tic_long"
WHERE indicador = 'EMPRESAS, POR TIPO DE CARGOS EXISTENTES'
  AND recorte_tipo = 'MERCADOS DE ATUAÇÃO'
  AND recorte = 'Indústria de transformação'
  AND coluna LIKE '%| Sim'
ORDER BY 
    edicao DESC, 
    valor_pct DESC;