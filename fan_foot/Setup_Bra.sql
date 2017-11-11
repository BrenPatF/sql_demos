PROMPT Create Brazil tables...
DROP TABLE brazil_positions
/
CREATE TABLE brazil_positions (
        id              VARCHAR2(2) PRIMARY KEY,
        min_players     INTEGER,
        max_players     INTEGER
)
/
DROP TABLE brazil_players
/
CREATE TABLE brazil_players (
        id              VARCHAR2(3) PRIMARY KEY,
        club_name       VARCHAR2(30),
        player_name     VARCHAR2(30),
        position        VARCHAR2(2),
        price           NUMBER,
        avg_points      NUMBER,
        appearances     NUMBER
)  
/
PROMPT Insert Brazil data
DECLARE

  i     PLS_INTEGER := 0;
  PROCEDURE Ins_Position (
                        p_id	        VARCHAR2,
                        p_min_players   PLS_INTEGER,
                        p_max_players   PLS_INTEGER) IS
  BEGIN

    INSERT INTO brazil_positions VALUES (p_id, p_min_players, p_max_players);

  END Ins_Position;

  PROCEDURE Ins_Player (p_club_name    VARCHAR2,
                        p_player_name  VARCHAR2, 
                        p_position     VARCHAR2,
                        p_price        NUMBER,
                        p_avg_points   NUMBER,
                        p_appearances  PLS_INTEGER) IS
  BEGIN

    i := i + 1;
    INSERT INTO brazil_players VALUES (LPad (i, 3, '0'), p_club_name, p_player_name, p_position, 100*p_price, 100*p_avg_points, 100*p_appearances);

  END Ins_Player;

BEGIN

  DELETE brazil_positions;
  Ins_Position ('CO', 1, 1);
  Ins_Position ('GK', 1, 1);
  Ins_Position ('CB', 2, 3);
  Ins_Position ('WB', 0, 2);
  Ins_Position ('MF', 3, 5);
  Ins_Position ('FW', 1, 3);
  Ins_Position ('AL', 12, 12);

  DELETE brazil_players;
  Ins_Player ('Atlético-PR', 'Éderson', 'FW', 17.12, 10.12, 5);  
  Ins_Player ('Vitória', 'Maxi Biancucchi', 'FW', 19.62, 10.05, 4);  
  Ins_Player ('Fluminense', 'Rafael Sobis', 'FW', 23.03, 9.55, 4);  
  Ins_Player ('Bahia', 'Fernandão', 'FW', 13.28, 8.22, 5);  
  Ins_Player ('São Paulo', 'Luis Fabiano', 'FW', 21.54, 7.58, 4);  
  Ins_Player ('Botafogo', 'Rafael Marques', 'FW', 19.74, 6.68, 5);  
  Ins_Player ('Cruzeiro', 'Dagoberto', 'FW', 22.11, 5.94, 5);  
  Ins_Player ('Náutico', 'Rogério', 'FW', 10.62, 5.7, 5);  
  Ins_Player ('Flamengo', 'Hernane', 'FW', 13.87, 4.98, 5);  
  Ins_Player ('Crisciúma', 'Lins', 'FW', 18.4, 4.9, 5);  
  Ins_Player ('Santos', 'Neilton', 'FW', 6.38, 4.88, 4);  
  Ins_Player ('Fluminense', 'Samuel', 'FW', 10.01, 4.87, 3);  
  Ins_Player ('Ponte Preta', 'Chiquinho', 'FW', 9.97, 4.64, 5);  
  Ins_Player ('Atlético-MG', 'Luan', 'FW', 13.18, 4.55, 4);  
  Ins_Player ('Ponte Preta', 'William', 'FW', 13.93, 4.44, 5);  
  Ins_Player ('Botafogo', 'Vitinho', 'FW', 10.2, 4.04, 5);  
  Ins_Player ('Coritiba', 'Deivid', 'FW', 15.9, 3.76, 5);  
  Ins_Player ('Grêmio', 'Barcos', 'FW', 18.96, 3.67, 4);  
  Ins_Player ('Atlético-MG', 'Jô', 'FW', 13.93, 3.4, 2);  
  Ins_Player ('São Paulo', 'Osvaldo', 'FW', 13.64, 3.12, 5);  
  Ins_Player ('Cruzeiro', 'Fábio', 'GK', 20.9, 7.94, 5);  
  Ins_Player ('Vitória', 'Wilson', 'GK', 12.39, 7.94, 5);  
  Ins_Player ('Coritiba', 'Vanderlei', 'GK', 18.58, 7.76, 5);  
  Ins_Player ('Atlético-MG', 'Victor', 'GK', 11.63, 4.67, 4);  
  Ins_Player ('Bahia', 'Marcelo Lomba', 'GK', 13.64, 4.5, 5);  
  Ins_Player ('Botafogo', 'Renan', 'GK', 6.77, 4.37, 4);  
  Ins_Player ('Flamengo', 'Felipe', 'GK', 15.26, 4.14, 5);  
  Ins_Player ('Grêmio', 'Dida', 'GK', 11.32, 3.75, 4);  
  Ins_Player ('Corinthians', 'Cássio', 'GK', 12.51, 3.74, 5);  
  Ins_Player ('Vasco', 'Michel Alves', 'GK', 8.99, 3.48, 5);  
  Ins_Player ('Crisciúma', 'Bruno', 'GK', 10.66, 3.2, 5);  
  Ins_Player ('Internacional', 'Muriel', 'GK', 9.81, 3.1, 4);  
  Ins_Player ('Santos', 'Rafael', 'GK', 17.82, 3, 5);  
  Ins_Player ('Atlético-PR', 'Weverton', 'GK', 6.16, 2.48, 5);  
  Ins_Player ('Fluminense', 'Ricardo Berna', 'GK', 4.6, 2.42, 4);  
  Ins_Player ('Portuguesa', 'Gledson', 'GK', 4.52, 2.1, 4);  
  Ins_Player ('São Paulo', 'Rogério Ceni', 'GK', 14.2, 1.17, 4);  
  Ins_Player ('Portuguesa', 'Ivan', 'WB', 7.55, 13.2, 1);  
  Ins_Player ('Vasco', 'Elsinho', 'WB', 14.68, 8.5, 4);  
  Ins_Player ('Cruzeiro', 'Egídio', 'WB', 14.82, 7.52, 5);  
  Ins_Player ('Fluminense', 'Carlinhos', 'WB', 12.4, 6.93, 3);  
  Ins_Player ('Náutico', 'Auremir', 'WB', 7.73, 5.48, 4);  
  Ins_Player ('Cruzeiro', 'Mayke', 'WB', 3.74, 5.25, 2);  
  Ins_Player ('Portuguesa', 'Luis Ricardo', 'WB', 8.58, 4.67, 3);  
  Ins_Player ('Atlético-MG', 'Richarlyson', 'WB', 10.2, 4.67, 3);  
  Ins_Player ('Internacional', 'Fabrício', 'WB', 8.76, 4.57, 4);  
  Ins_Player ('São Paulo', 'Juan', 'WB', 7.89, 4.57, 3);  
  Ins_Player ('São Paulo', 'Paulo Miranda', 'WB', 10.53, 4.54, 5);  
  Ins_Player ('Flamengo', 'João Paulo', 'WB', 7.15, 4.53, 3);  
  Ins_Player ('São Paulo', 'Rodrigo Caio', 'WB', 11.92, 4.52, 5);  
  Ins_Player ('Coritiba', 'Victor Ferraz', 'WB', 13.04, 4.2, 5);  
  Ins_Player ('Bahia', 'Jussandro', 'WB', 6.94, 4.1, 5);  
  Ins_Player ('Santos', 'Rafael Galhardo', 'WB', 12.88, 4.04, 5);  
  Ins_Player ('Goiás', 'William Matheus', 'WB', 5.87, 4.02, 5);  
  Ins_Player ('Náutico', 'Maranhão', 'WB', 6.53, 4.02, 5);  
  Ins_Player ('Internacional', 'Gabriel', 'WB', 11.81, 3.38, 5);  
  Ins_Player ('Goiás', 'Vítor', 'WB', 8.77, 3.36, 5);  
  Ins_Player ('Internacional', 'Fred', 'MF', 30.28, 8.92, 5);  
  Ins_Player ('Grêmio', 'Zé Roberto', 'MF', 25.93, 8.78, 4);  
  Ins_Player ('Internacional', 'Otavinho', 'MF', 7.62, 8.07, 3);  
  Ins_Player ('Vasco', 'Carlos Alberto', 'MF', 15.01, 6.75, 2);  
  Ins_Player ('Cruzeiro', 'Nilton', 'MF', 22.39, 6.46, 5);  
  Ins_Player ('Coritiba', 'Júnior Urso', 'MF', 14.38, 6.22, 5);  
  Ins_Player ('Crisciúma', 'João Vitor', 'MF', 13.27, 6.04, 5);  
  Ins_Player ('Corinthians', 'Guilherme', 'MF', 8.83, 5.87, 4);  
  Ins_Player ('Corinthians', 'Ralf', 'MF', 19.65, 5.7, 5);  
  Ins_Player ('Vitória', 'Escudero', 'MF', 16.38, 5.68, 5);  
  Ins_Player ('Portuguesa', 'Correa', 'MF', 8.44, 5.6, 4);  
  Ins_Player ('Portuguesa', 'Souza', 'MF', 12.62, 5.17, 4);  
  Ins_Player ('Coritiba', 'Alex', 'MF', 16.98, 5.08, 5);  
  Ins_Player ('Grêmio', 'Souza', 'MF', 13.8, 4.98, 4);  
  Ins_Player ('Ponte Preta', 'Cicinho', 'MF', 11.42, 4.72, 5);  
  Ins_Player ('Botafogo', 'Fellype Gabriel', 'MF', 8.6, 4.47, 4);  
  Ins_Player ('Atlético-PR', 'João Paulo', 'MF', 10.56, 4.38, 5);  
  Ins_Player ('Vasco', 'Sandro Silva', 'MF', 10.76, 4.28, 5);  
  Ins_Player ('Santos', 'Cícero', 'MF', 14.15, 4.18, 5);  
  Ins_Player ('Fluminense', 'Wagner', 'MF', 8.55, 4.13, 3);  
  Ins_Player ('Flamengo', 'Jaime De AlMFda', 'CO', 11.56, 8.03, 1);  
  Ins_Player ('Cruzeiro', 'Marcelo Oliveira', 'CO', 16.11, 5.43, 5);  
  Ins_Player ('Fluminense', 'Abel Braga', 'CO', 17.51, 5.36, 4);  
  Ins_Player ('Internacional', 'Dunga', 'CO', 14.22, 4.63, 5);  
  Ins_Player ('Vitória', 'Caio Júnior', 'CO', 11.4, 4.45, 5);  
  Ins_Player ('Grêmio', 'Vanderlei Luxemburgo', 'CO', 15.77, 4.42, 4);  
  Ins_Player ('São Paulo', 'Ney Franco', 'CO', 15.15, 4.39, 5);  
  Ins_Player ('Náutico', 'Levi Gomes', 'CO', 7.08, 4.2, 2);  
  Ins_Player ('Atlético-PR', 'Ricardo Drubscky', 'CO', 7.96, 3.92, 5);  
  Ins_Player ('Coritiba', 'Marquinhos Santos', 'CO', 10.59, 3.89, 5);  
  Ins_Player ('Vasco', 'Paulo Autuori', 'CO', 13.13, 3.61, 5);  
  Ins_Player ('Portuguesa', 'Edson Pimenta', 'CO', 3.67, 3.26, 4);  
  Ins_Player ('Botafogo', 'Oswaldo De Oliveira', 'CO', 10.77, 3.23, 5);  
  Ins_Player ('Corinthians', 'Tite', 'CO', 13.68, 3.17, 5);  
  Ins_Player ('Santos', 'Claudinei Oliveira', 'CO', 11.92, 3.17, 3);  
  Ins_Player ('Bahia', 'Cristóvão Borges', 'CO', 8.27, 2.92, 5);  
  Ins_Player ('Crisciúma', 'Vadão', 'CO', 7.04, 2.86, 5);  
  Ins_Player ('Goiás', 'Enderson Moreira', 'CO', 6.8, 2.53, 5);  
  Ins_Player ('Atlético-MG', 'Cuca', 'CO', 12.62, 2.32, 4);  
  Ins_Player ('Ponte Preta', 'Zé Sérgio', 'CO', 6.85, .75, 1);  
  Ins_Player ('Fluminense', 'Digão', 'CB', 9.31, 9.27, 3);  
  Ins_Player ('Flamengo', 'Samir', 'CB', 2.67, 6.8, 1);  
  Ins_Player ('Cruzeiro', 'Dedé', 'CB', 22.54, 6.4, 5);  
  Ins_Player ('São Paulo', 'Lúcio', 'CB', 21.71, 6.02, 5);  
  Ins_Player ('Grêmio', 'Bressan', 'CB', 10.85, 5.9, 4);  
  Ins_Player ('Atlético-PR', 'Manoel', 'CB', 16.99, 5.88, 5);  
  Ins_Player ('Ponte Preta', 'Cléber', 'CB', 14.61, 5.78, 5);  
  Ins_Player ('Cruzeiro', 'Bruno Rodrigo', 'CB', 15.47, 5.28, 5);  
  Ins_Player ('Santos', 'Edu Dracena', 'CB', 16.82, 4.97, 3);  
  Ins_Player ('Náutico', 'William Alves', 'CB', 5.56, 4.43, 3);  
  Ins_Player ('Fluminense', 'Gum', 'CB', 12.18, 4.22, 4);  
  Ins_Player ('Flamengo', 'Wallace', 'CB', 4.29, 4.2, 2);  
  Ins_Player ('Náutico', 'João Filipe', 'CB', 5.47, 4.1, 4);  
  Ins_Player ('Grêmio', 'Werley', 'CB', 15.9, 4.03, 4);  
  Ins_Player ('Corinthians', 'Gil', 'CB', 13.23, 3.98, 5);  
  Ins_Player ('Vitória', 'Gabriel Paulista', 'CB', 11.77, 3.94, 5);  
  Ins_Player ('Goiás', 'Ernando', 'CB', 10.24, 3.74, 5);
--  DELETE players WHERE player_name > 'Cristóvão Borges';--'Gil';-- 'Cássio';
END;
/
