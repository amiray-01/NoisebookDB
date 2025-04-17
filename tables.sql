DROP TABLE IF EXISTS utilisateurs CASCADE;
DROP TABLE IF EXISTS personne CASCADE;
DROP TABLE IF EXISTS groupe CASCADE;
DROP TABLE IF EXISTS association CASCADE;
DROP TABLE IF EXISTS salledeconcert CASCADE;
DROP TABLE IF EXISTS follow CASCADE;
DROP TABLE IF EXISTS ami CASCADE;
DROP TABLE IF EXISTS concert CASCADE;
DROP TABLE IF EXISTS annonce CASCADE;
DROP TABLE IF EXISTS organise CASCADE;
DROP TABLE IF EXISTS performe CASCADE;
DROP TABLE IF EXISTS archive_concert CASCADE;
DROP TABLE IF EXISTS archive_avis_concert CASCADE;
DROP TABLE IF EXISTS avis_concert CASCADE;
DROP TABLE IF EXISTS avis_groupe CASCADE;
DROP TABLE IF EXISTS avis_lieu CASCADE;
DROP TABLE IF EXISTS avis_morceau CASCADE;
DROP TABLE IF EXISTS participation CASCADE;
DROP TABLE IF EXISTS avis CASCADE;
DROP TABLE IF EXISTS commentaire CASCADE;
DROP TABLE IF EXISTS motcles CASCADE;
DROP TABLE IF EXISTS motcles_association CASCADE;
DROP TABLE IF EXISTS motcles_groupe CASCADE;
DROP TABLE IF EXISTS motcles_avis CASCADE;
DROP TABLE IF EXISTS motcles_salledeconcert CASCADE;
DROP TABLE IF EXISTS motcles_playlist CASCADE;
DROP TABLE IF EXISTS playlist CASCADE;
DROP TABLE IF EXISTS morceau CASCADE;
DROP TABLE IF EXISTS playlist_morceau CASCADE;
DROP TABLE IF EXISTS genre CASCADE;
DROP TABLE IF EXISTS genre_sous_genre CASCADE;
DEALLOCATE PREPARE morceaux_playlist;
DEALLOCATE PREPARE concerts_assoc;
DEALLOCATE PREPARE users_follow_groupe;
DEALLOCATE PREPARE chaine_ami;
DEALLOCATE PREPARE users_genre;


CREATE TABLE utilisateurs(
    uid SERIAL PRIMARY KEY,
    pseudo VARCHAR(30) UNIQUE,
    email VARCHAR(100) UNIQUE
);

CREATE TABLE personne (
    uid INT PRIMARY KEY REFERENCES utilisateurs (uid),
    nom VARCHAR(20) NOT NULL,
    prenom VARCHAR(20) NOT NULL,
    sexe VARCHAR(1) NOT NULL,
    date_naissance DATE
);

CREATE TABLE association(
    uid INT PRIMARY KEY REFERENCES utilisateurs (uid),
    nom_association VARCHAR(255) NOT NULL,
    date_creation DATE
);

CREATE TABLE salledeconcert(
    uid INT PRIMARY KEY REFERENCES utilisateurs (uid),
    nom_salle VARCHAR(255) NOT NULL,
    adresse VARCHAR(255) NOT NULL,
    date_creation DATE
);

CREATE TABLE genre(
    id_genre SERIAL PRIMARY KEY,
    nom_genre VARCHAR(30) NOT NULL,
    CONSTRAINT unique_genre UNIQUE (nom_genre)
);

CREATE TABLE genre_sous_genre(
    id_genre INTEGER NOT NULL,
    id_sous_genre INTEGER NOT NULL,
    FOREIGN KEY (id_genre) REFERENCES genre(id_genre),
    FOREIGN KEY (id_sous_genre) REFERENCES genre(id_genre),
    PRIMARY KEY(id_genre, id_sous_genre)
);

CREATE TABLE groupe(
    uid INT PRIMARY KEY REFERENCES utilisateurs (uid),
    nom_groupe VARCHAR(30) NOT NULL,
    date_creation DATE,
    genre_musical INTEGER NOT NULL,
    FOREIGN KEY (genre_musical) REFERENCES genre(id_genre)
);

CREATE TABLE follow (
    id_utilisateur_suiveur INTEGER NOT NULL,
    id_utilisateur_suivi INTEGER NOT NULL,
    FOREIGN KEY (id_utilisateur_suiveur) REFERENCES utilisateurs(uid),
    FOREIGN KEY (id_utilisateur_suivi) REFERENCES utilisateurs(uid), 
    PRIMARY KEY (id_utilisateur_suiveur, id_utilisateur_suivi),
    CONSTRAINT ck_follow CHECK (id_utilisateur_suiveur <> id_utilisateur_suivi)
);

CREATE TABLE ami (
    id_utilisateur_1 INTEGER NOT NULL,
    id_utilisateur_2 INTEGER NOT NULL,
    FOREIGN KEY (id_utilisateur_1) REFERENCES utilisateurs(uid),
    FOREIGN KEY (id_utilisateur_2) REFERENCES utilisateurs(uid),
    PRIMARY KEY (id_utilisateur_1, id_utilisateur_2),
    check(id_utilisateur_1 < id_utilisateur_2)
);

CREATE TABLE concert(
    id_concert SERIAL PRIMARY KEY,
    nom_concert VARCHAR(255) NOT NULL,
    date_concert DATE NOT NULL,
    heure_concert TIME NOT NULL,
    prix INTEGER NOT NULL,
    places_dispos INTEGER NOT NULL,
    description TEXT,
    salle INTEGER NOT NULL,
    genre INTEGER NOT NULL,
    FOREIGN KEY (salle) REFERENCES salledeconcert(uid),
    FOREIGN KEY (genre) REFERENCES genre(id_genre)
);

CREATE TABLE annonce (
    id_utilisateur INTEGER NOT NULL,
    id_concert INTEGER NOT NULL,
    FOREIGN KEY (id_utilisateur) REFERENCES utilisateurs(uid),
    FOREIGN KEY (id_concert) REFERENCES concert(id_concert),
    PRIMARY KEY(id_utilisateur, id_concert),
    CONSTRAINT UNIQUE_annonce UNIQUE (id_utilisateur, id_concert)
);

CREATE TABLE organise(
    id_assoc INTEGER NOT NULL,
    concert INTEGER NOT NULL,
    date_organisation DATE NOT NULL,
    FOREIGN KEY (id_assoc) REFERENCES association(uid),
    FOREIGN KEY (concert) REFERENCES concert(id_concert),
    PRIMARY KEY(id_assoc, concert),
    CONSTRAINT UNIQUE_organise UNIQUE (id_assoc, concert),
    CONSTRAINT fk_organise_association FOREIGN KEY (id_assoc)
        REFERENCES utilisateurs(uid) ON DELETE CASCADE,
    CONSTRAINT fk_organise_concert FOREIGN KEY (concert)
        REFERENCES concert(id_concert) ON DELETE CASCADE
);
-- Dans cet exemple, la table "organise" relie les utilisateurs aux concerts qu'ils 
--   organisent en utilisant leurs clés primaires respectives (id_utilisateur et id_concert). 
--    La contrainte pk_organise définit une contrainte de clé primaire sur la paire (id_utilisateur, id_concert) 
--    pour garantir l'unicité des enregistrements dans la table. 
--    Les contraintes fk_organise_utilisateur et fk_organise_concert définissent des contraintes de clé étrangère sur les colonnes id_utilisateur et id_concert, respectivement,
--    pour s'assurer que les utilisateurs et les concerts référencés existent dans leurs tables respectives (utilisateur et concert). La clause ON DELETE CASCADE indique que si un utilisateur ou un concert est supprimé, toutes les entrées correspondantes dans la table "organise" seront également supprimées.

CREATE TABLE performe (
    id_groupe INTEGER NOT NULL,
    concert INTEGER NOT NULL,
    FOREIGN KEY (id_groupe) REFERENCES groupe(uid),
    FOREIGN KEY (concert) REFERENCES concert(id_concert),
    temps_debut TIMESTAMP NOT NULL,
    temps_fin TIMESTAMP,
    PRIMARY KEY(id_groupe, concert),
    CONSTRAINT fk_performe_utilisateur FOREIGN KEY (id_groupe) REFERENCES groupe(uid),
    CONSTRAINT fk_performe_concert FOREIGN KEY (concert) REFERENCES concert(id_concert),
    CONSTRAINT ck_performe_temps CHECK (temps_fin IS NULL OR temps_fin > temps_debut)
);
--Dans ce schéma, chaque enregistrement de la table performe lie un utilisateur à un concert, en spécifiant le moment où la performance a commencé (temps_debut) et le moment où elle s'est terminée (temps_fin). La clé primaire de la table est composée de l'id_utilisateur, de l'id_concert et du temps_debut, car un utilisateur peut avoir plusieurs performances lors du même concert, et une performance peut avoir lieu à des moments différents du concert.
--La contrainte fk_performe_utilisateur assure que l'id_utilisateur dans la table performe référence un enregistrement existant dans la table utilisateur. De même, la contrainte fk_performe_concert assure que l'id_concert dans la table performe référence un enregistrement existant dans la table concert.
--La contrainte ck_performe_temps assure que la valeur de temps_fin est toujours supérieure à celle de temps_debut. Si temps_fin n'a pas encore été spécifié (c'est-à-dire que la performance est en cours), sa valeur est NULL.

CREATE TABLE participation (
    id_personne INTEGER NOT NULL,
    concert INTEGER NOT NULL,
    FOREIGN KEY (id_personne) REFERENCES personne(uid),
    FOREIGN KEY (concert) REFERENCES concert(id_concert),
    PRIMARY KEY(id_personne, concert),
    participe BOOLEAN NOT NULL,
    interesse BOOLEAN NOT NULL,
    CONSTRAINT fk_paricipation_utilisateur FOREIGN KEY (id_personne) REFERENCES personne(uid),
    CONSTRAINT fk_paricipation_concert FOREIGN KEY (concert) REFERENCES concert(id_concert),
    CONSTRAINT p_or_i CHECK ((participe AND NOT interesse) OR (interesse AND NOT participe))
);

CREATE TABLE archive_concert(
    id_utilisateur INTEGER NOT NULL,
    concert INTEGER NOT NULL,
    date_concert DATE NOT NULL,
    FOREIGN KEY (concert) REFERENCES concert(id_concert),
    FOREIGN KEY (id_utilisateur) REFERENCES utilisateurs(uid),
    date_archivage DATE NOT NULL,
    PRIMARY KEY(concert, date_archivage),
    CONSTRAINT ck_concert_passe CHECK (date_archivage < CURRENT_DATE),
    CONSTRAINT ck_date_concert CHECK ((date_concert < date_archivage) AND (date_concert < CURRENT_DATE) AND (date_archivage <= CURRENT_DATE))
);

CREATE TABLE morceau(
    id_morceau SERIAL PRIMARY KEY,
    id_genre INTEGER NOT NULL,
    FOREIGN KEY (id_genre) REFERENCES genre(id_genre),
    titre VARCHAR(20) NOT NULL,
    duree INTEGER NOT NULL,
    artiste VARCHAR(20) NOT NULL  --à revoir peut etre mettre uid utilisateur)
);

CREATE TABLE playlist(
    id_playlist SERIAL PRIMARY KEY,
    id_utilisateur INTEGER NOT NULL,
    FOREIGN KEY (id_utilisateur) REFERENCES utilisateurs(uid),
    nom_playlist VARCHAR(25) NOT NULL,
    CONSTRAINT UNIQUE_playlist UNIQUE (id_utilisateur, nom_playlist)
);

CREATE TABLE playlist_morceau(
    id_playlist INTEGER NOT NULL,
    id_morceau INTEGER NOT NULL,
    FOREIGN KEY (id_playlist) REFERENCES playlist(id_playlist),
    FOREIGN KEY (id_morceau) REFERENCES morceau(id_morceau),
    PRIMARY KEY (id_playlist, id_morceau)
);

CREATE TABLE avis(
    id_avis SERIAL PRIMARY KEY,
    id_utilisateur INTEGER NOT NULL,
    FOREIGN KEY (id_utilisateur) REFERENCES utilisateurs(uid),
    note INTEGER NOT NULL,
    check (note >= 0 and note <= 10)
);

CREATE TABLE avis_groupe(
    id_avis INTEGER PRIMARY KEY REFERENCES avis(id_avis),
    id_groupe INTEGER NOT NULL,
    FOREIGN KEY (id_groupe) REFERENCES groupe(uid)
);

CREATE TABLE avis_morceau(
    id_avis INTEGER PRIMARY KEY REFERENCES avis(id_avis),
    id_morceau INTEGER NOT NULL,
    FOREIGN KEY (id_morceau) REFERENCES morceau(id_morceau)
);

CREATE TABLE avis_concert(
    id_avis INTEGER PRIMARY KEY REFERENCES avis(id_avis),
    id_concert INTEGER NOT NULL,
    FOREIGN KEY (id_concert) REFERENCES concert(id_concert)
);

CREATE TABLE avis_lieu(
    id_avis INTEGER PRIMARY KEY REFERENCES avis(id_avis),
    id_lieu INTEGER NOT NULL,
    FOREIGN KEY (id_lieu) REFERENCES salledeconcert(uid)
);

CREATE TABLE archive_avis_concert(
    id_avis INTEGER NOT NULL,
    id_concert INTEGER NOT NULL,
    FOREIGN KEY (id_avis) REFERENCES avis_concert(id_avis),
    FOREIGN KEY (id_concert) REFERENCES concert(id_concert),
    PRIMARY KEY(id_avis, id_concert)
);

CREATE TABLE commentaire(
    id_avis INTEGER NOT NULL,
    FOREIGN KEY (id_avis) REFERENCES avis(id_avis),
    comment TEXT NOT NULL,
    PRIMARY KEY(id_avis , comment)
);

CREATE TABLE motcles(
    id_motcles SERIAL PRIMARY KEY,
    motcles VARCHAR(20) NOT NULL
);

CREATE TABLE motcles_avis(
    id_avis INTEGER NOT NULL,
    id_motcles INTEGER NOT NULL,
    FOREIGN KEY (id_avis) REFERENCES avis(id_avis),
    FOREIGN KEY (id_motcles) REFERENCES motcles(id_motcles),
    PRIMARY KEY(id_avis, id_motcles)
);

CREATE TABLE motcles_association(
    id_motcles INTEGER NOT NULL,
    id_association INTEGER NOT NULL,
    FOREIGN KEY (id_motcles) REFERENCES motcles(id_motcles),
    FOREIGN KEY (id_association) REFERENCES association(uid),
    PRIMARY KEY(id_motcles, id_association)
);

CREATE TABLE motcles_salledeconcert(
    id_motcles INTEGER NOT NULL,
    id_salle INTEGER NOT NULL,
    FOREIGN KEY (id_motcles) REFERENCES motcles(id_motcles),
    FOREIGN KEY (id_salle) REFERENCES salledeconcert(uid),
    PRIMARY KEY(id_motcles, id_salle)
);

CREATE TABLE motcles_groupe(
    id_motcles INTEGER NOT NULL,
    id_groupe INTEGER NOT NULL,
    FOREIGN KEY (id_motcles) REFERENCES motcles(id_motcles),
    FOREIGN KEY (id_groupe) REFERENCES groupe(uid),
    PRIMARY KEY(id_motcles, id_groupe)
);

CREATE TABLE motcles_playlist(
    id_motcles INTEGER NOT NULL,
    id_playlist INTEGER NOT NULL,
    FOREIGN KEY (id_motcles) REFERENCES motcles(id_motcles),
    FOREIGN KEY (id_playlist) REFERENCES playlist(id_playlist),
    PRIMARY KEY(id_motcles, id_playlist)
);

-- copie des données

\COPY utilisateurs FROM 'data_csv/utilisateurs.csv' DELIMITER ',' CSV HEADER;
\COPY personne FROM 'data_csv/personne.csv' DELIMITER ',' CSV HEADER;
\COPY association FROM 'data_csv/association.csv' DELIMITER ',' CSV HEADER;
\COPY salledeconcert FROM 'data_csv/salledeconcert.csv' DELIMITER ',' CSV HEADER;
\COPY follow FROM 'data_csv/follow.csv' DELIMITER ',' CSV HEADER;
\COPY ami FROM 'data_csv/ami.csv' DELIMITER ',' CSV HEADER;
\COPY genre FROM 'data_csv/genre.csv' DELIMITER ',' CSV HEADER;
\COPY genre_sous_genre FROM 'data_csv/genre_sous_genre.csv' DELIMITER ',' CSV HEADER;
\COPY groupe FROM 'data_csv/groupe.csv' DELIMITER ',' CSV HEADER;
\COPY concert FROM 'data_csv/concert.csv' DELIMITER ',' CSV HEADER;
\COPY annonce FROM 'data_csv/annonce.csv' DELIMITER ',' CSV HEADER;
\COPY organise FROM 'data_csv/organise.csv' DELIMITER ',' CSV HEADER;
\COPY performe from 'data_csv/performance.csv' DELIMITER ',' CSV HEADER;
\COPY participation from 'data_csv/participe.csv' DELIMITER ',' CSV HEADER;
\COPY archive_concert from 'data_csv/archive_concert.csv' DELIMITER ',' CSV HEADER;
\COPY morceau from 'data_csv/morceau.csv' DELIMITER ',' CSV HEADER;
\COPY playlist from 'data_csv/playlist.csv' DELIMITER ',' CSV HEADER;
\COPY playlist_morceau from 'data_csv/playlist_morceau.csv' DELIMITER ',' CSV HEADER;
\COPY avis from 'data_csv/avis.csv' DELIMITER ',' CSV HEADER;
\COPY avis_groupe from 'data_csv/avis_groupe.csv' DELIMITER ',' CSV HEADER;
\COPY avis_morceau from 'data_csv/avis_morceau.csv' DELIMITER ',' CSV HEADER;
\COPY avis_concert from 'data_csv/avis_concert.csv' DELIMITER ',' CSV HEADER;
\COPY avis_lieu from 'data_csv/avis_lieu.csv' DELIMITER ',' CSV HEADER;
\COPY archive_avis_concert from 'data_csv/archive_avis_concert.csv' DELIMITER ',' CSV HEADER;
\COPY commentaire from 'data_csv/commentaire.csv' DELIMITER ',' CSV HEADER;
\COPY motcles from 'data_csv/motcles.csv' DELIMITER ',' CSV HEADER;
\COPY motcles_avis from 'data_csv/motcles_avis.csv' DELIMITER ',' CSV HEADER;
\COPY motcles_association from 'data_csv/motcles_association.csv' DELIMITER ',' CSV HEADER;
\COPY motcles_salledeconcert from 'data_csv/motcles_salledeconcert.csv' DELIMITER ',' CSV HEADER;
\COPY motcles_groupe from 'data_csv/motcles_groupe.csv' DELIMITER ',' CSV HEADER;
\COPY motcles_playlist from 'data_csv/motcles_playlist.csv' DELIMITER ',' CSV HEADER;


--Requetes préparées
--Afficher les concerts organisés par une association donnée, avec les détails sur la salle de concert et le genre musical.
PREPARE concerts_assoc(VARCHAR) AS
SELECT c.nom_concert,s.nom_salle,s.adresse,g.nom_genre
FROM concert as c
JOIN salledeconcert s ON c.salle = s.uid
JOIN genre g ON c.genre = g.id_genre
JOIN organise o ON c.id_concert = o.concert
JOIN association a ON o.id_assoc = a.uid
WHERE a.nom_association = $1;

--Retourner tous les utilisateurs qui suivent au moins un groupe dont le genre musical est '$1'.
PREPARE users_follow_groupe(VARCHAR) AS
SELECT u.pseudo FROM utilisateurs u 
WHERE EXISTS (
    SELECT 1
    FROM follow f
    JOIN groupe g ON f.id_utilisateur_suivi = g.uid
    JOIN genre g1 ON g.genre_musical = g1.id_genre
    WHERE f.id_utilisateur_suiveur = u.uid
    AND g1.nom_genre = $1
);

--Donne les morceaux d'une playlist
PREPARE morceaux_playlist(INTEGER) AS
SELECT M.titre, M.duree, M.artiste
FROM morceau M
INNER JOIN playlist_morceau PM ON M.id_morceau = PM.id_morceau
INNER JOIN playlist P ON PM.id_playlist = P.id_playlist
WHERE P.id_playlist = $1;

--liste tous les amis d'un utilisateur '$1', ainsi que les amis de ses amis a un niveau '$2'
PREPARE chaine_ami(INTEGER,INTEGER) AS
WITH RECURSIVE friend_network AS (
  SELECT uid, pseudo, 1 AS niveau
  FROM utilisateurs
  WHERE uid = $1

  UNION
  
  SELECT u.uid, u.pseudo, fn.niveau + 1
  FROM utilisateurs u
  INNER JOIN friend_network fn ON u.uid IN (SELECT id_utilisateur_2 FROM ami WHERE id_utilisateur_1 = fn.uid)
  WHERE fn.niveau < $2
)
SELECT uid, pseudo
FROM friend_network
ORDER BY uid;

--Trouver les utilisateurs qui suivent tous les groupes de musique d'un genre '$1'.
PREPARE users_genre(VARCHAR) AS 
SELECT u.pseudo
FROM utilisateurs u
JOIN follow f ON u.uid = f.id_utilisateur_suiveur
JOIN groupe g ON f.id_utilisateur_suivi = g.uid
JOIN genre genre1 ON g.genre_musical = genre1.id_genre
WHERE genre1.nom_genre = $1
GROUP BY u.uid, u.pseudo
HAVING COUNT(DISTINCT g.uid) = (
    SELECT COUNT(*)
    FROM groupe g2
    JOIN genre genre2 ON g2.genre_musical = genre2.id_genre
    WHERE genre2.nom_genre = $1
);