-- Criando o banco de dados
CREATE DATABASE ExpansaoVarejo;
USE ExpansaoVarejo;

-- Tabela de Perfil Sociodemográfico da População
CREATE TABLE Perfil_Sociodemografico (
    id INT AUTO_INCREMENT PRIMARY KEY,
    regiao VARCHAR(100),
    populacao_total INT,
    renda_media DECIMAL(10,2),
    idade_media DECIMAL(5,2),
    taxa_crescimento DECIMAL(5,2),
    densidade_populacional DECIMAL(10,2)
);

-- Tabela de Concorrência
CREATE TABLE Concorrencia (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome_loja VARCHAR(100),
    categoria VARCHAR(50),
    endereco VARCHAR(255),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    faturamento_estimado DECIMAL(15,2)
);

-- Tabela de Desempenho das Lojas Atuais
CREATE TABLE Desempenho_Lojas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome_loja VARCHAR(100),
    endereco VARCHAR(255),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    faturamento_mensal DECIMAL(15,2),
    ticket_medio DECIMAL(10,2),
    fluxo_clientes INT,
    custo_operacional DECIMAL(15,2)
);

-- Tabela para armazenar sugestões de expansão
CREATE TABLE Expansao_Sugerida (
    id INT AUTO_INCREMENT PRIMARY KEY,
    regiao VARCHAR(100),
    potencial_clientes INT,
    concorrentes_proximos INT,
    estimativa_faturamento DECIMAL(15,2),
    viabilidade DECIMAL(5,2) -- Indicador de viabilidade baseado em análise preditiva
);

-- Inserindo dados fictícios na tabela Perfil Sociodemográfico
INSERT INTO Perfil_Sociodemografico (regiao, populacao_total, renda_media, idade_media, taxa_crescimento, densidade_populacional) VALUES
('Centro', 50000, 4500.00, 35.5, 1.2, 3000.00),
('Zona Norte', 70000, 3200.00, 37.2, 0.9, 2500.00),
('Zona Sul', 60000, 5000.00, 33.8, 1.5, 2800.00);

-- Inserindo dados fictícios na tabela Concorrência
INSERT INTO Concorrencia (nome_loja, categoria, endereco, latitude, longitude, faturamento_estimado) VALUES
('Supermercado A', 'Supermercado', 'Rua das Flores, 123', -23.550520, -46.633308, 150000.00),
('Loja B', 'Vestuário', 'Avenida Central, 456', -23.551000, -46.632000, 80000.00),
('Padaria C', 'Alimentação', 'Rua da Paz, 789', -23.552000, -46.631000, 50000.00);

-- Inserindo dados fictícios na tabela Desempenho das Lojas Atuais
INSERT INTO Desempenho_Lojas (nome_loja, endereco, latitude, longitude, faturamento_mensal, ticket_medio, fluxo_clientes, custo_operacional) VALUES
('Loja 1', 'Rua A, 100', -23.550000, -46.630000, 200000.00, 50.00, 4000, 80000.00),
('Loja 2', 'Avenida B, 200', -23.551500, -46.629500, 180000.00, 45.00, 3800, 75000.00),
('Loja 3', 'Praça C, 300', -23.552500, -46.628500, 220000.00, 55.00, 4200, 85000.00);

-- Inserindo dados fictícios na tabela Expansao Sugerida
INSERT INTO Expansao_Sugerida (regiao, potencial_clientes, concorrentes_proximos, estimativa_faturamento, viabilidade) VALUES
('Zona Oeste', 60000, 3, 180000.00, 8.5),
('Centro Expandido', 75000, 5, 220000.00, 9.0);

ALTER TABLE Desempenho_Lojas ADD COLUMN regiao VARCHAR(255);
UPDATE Desempenho_Lojas SET regiao = 'Centro' WHERE nome_loja = 'Loja 1';
UPDATE Desempenho_Lojas SET regiao = 'Zona Sul' WHERE nome_loja = 'Loja 2';
UPDATE Desempenho_Lojas SET regiao = 'Zona Norte' WHERE nome_loja = 'Loja 3';

ALTER TABLE Concorrencia ADD COLUMN regiao VARCHAR(255);
UPDATE Concorrencia
SET nome_loja = CASE 
               WHEN nome_loja = 'Supermercado A' THEN 'Loja 1'
               WHEN nome_loja = 'Loja B' THEN 'Loja 2'
               WHEN nome_loja = 'Padaria C' THEN 'Loja 3'
               ELSE nome_loja
             END;
UPDATE Concorrencia SET regiao = 'Centro' WHERE nome_loja = 'Loja 1';
UPDATE Concorrencia SET regiao = 'Zona Sul' WHERE nome_loja = 'Loja 2';
UPDATE Concorrencia SET regiao = 'Zona Norte' WHERE nome_loja = 'Loja 3';

-- Cálculo por região: população total e renda média, número de concorrentes próximos e faturamento médio das lojas existentes.
USE expansaovarejo;
SELECT Perfil_Sociodemografico.regiao, 
       FORMAT(AVG(Perfil_Sociodemografico.populacao_total),2) AS populacao_media, 
       FORMAT(AVG(Perfil_Sociodemografico.renda_media),2) AS renda_media,
       FORMAT(COUNT(DISTINCT Concorrencia.id),2) AS num_concorrentes,
       FORMAT(AVG(Desempenho_Lojas.faturamento_mensal),2) AS faturamento_lojas_existentes
FROM Perfil_Sociodemografico
LEFT JOIN Concorrencia ON Perfil_Sociodemografico.regiao = Concorrencia.regiao
LEFT JOIN Desempenho_Lojas ON Perfil_Sociodemografico.regiao = Desempenho_Lojas.regiao
GROUP BY Perfil_Sociodemografico.regiao
LIMIT 1000;

-- Cálculo de índice de concorrência:
SELECT Concorrencia.regiao,
       (COUNT(DISTINCT Concorrencia.id) * 1000) / NULLIF(AVG(Perfil_Sociodemografico.populacao_total), 0) AS indice_concorrencia
FROM Perfil_Sociodemografico
LEFT JOIN Concorrencia ON Perfil_Sociodemografico.regiao = Concorrencia.regiao
GROUP BY Concorrencia.regiao;

-- Análise de Cluster (Segmentação de Regiões)
USE expansaovarejo;
WITH ranked AS (
    SELECT regiao, indice_atratividade,
           NTILE(3) OVER (ORDER BY indice_atratividade DESC) AS cluster
    FROM (
        SELECT Perfil_Sociodemografico.regiao,
               (AVG(Perfil_Sociodemografico.populacao_total) * 0.4 
               + AVG(Perfil_Sociodemografico.renda_media) * 0.3 
               - COUNT(DISTINCT Concorrencia.id) * 0.2 
               + AVG(Desempenho_Lojas.faturamento_mensal) * 0.1) AS indice_atratividade
        FROM Perfil_Sociodemografico
        LEFT JOIN Concorrencia ON Perfil_Sociodemografico.regiao = Concorrencia.regiao
        LEFT JOIN Desempenho_Lojas ON Perfil_Sociodemografico.regiao = Desempenho_Lojas.regiao
        GROUP BY Perfil_Sociodemografico.regiao
    ) subquery
)
SELECT regiao, indice_atratividade, 
       CASE 
           WHEN cluster = 1 THEN 'Alto Potencial'
           WHEN cluster = 2 THEN 'Médio Potencial'
           ELSE 'Baixo Potencial'
       END AS categoria_cluster
FROM ranked
ORDER BY indice_atratividade DESC;


-- Elasticidade da Demanda x Faturamento
SELECT FORMAT((SUM((Perfil_Sociodemografico.renda_media - (SELECT AVG(renda_media) FROM Perfil_Sociodemografico)) * 
         (Desempenho_Lojas.faturamento_mensal - (SELECT AVG(faturamento_mensal) FROM Desempenho_Lojas))) ) / 
    (SQRT(SUM(POW(Perfil_Sociodemografico.renda_media - (SELECT AVG(renda_media) FROM Perfil_Sociodemografico), 2)) * 
          SUM(POW(Desempenho_Lojas.faturamento_mensal - (SELECT AVG(faturamento_mensal) FROM Desempenho_Lojas), 2)))),2) AS correlacao
FROM Perfil_Sociodemografico
JOIN Desempenho_Lojas ON Perfil_Sociodemografico.regiao = Desempenho_Lojas.regiao;
