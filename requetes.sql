-- Requete 1 (au moins 3 jointure) : EXECUTE concerts_assoc(VARCHAR); 
--Afficher les concerts organisés par une association donnée, avec les détails sur la salle de concert et le genre musical.

SELECT c.nom_concert,s.nom_salle,s.adresse,g.nom_genre
FROM concert as c
JOIN salledeconcert s ON c.salle = s.uid
JOIN genre g ON c.genre = g.id_genre
JOIN organise o ON c.id_concert = o.concert
JOIN association a ON o.id_assoc = a.uid
WHERE a.nom_association = 'Association des Fans de Jazz';

--Requete 2 (jointure reflexive): 
--Retourner une liste des utilisateurs qui sont amis avec d'autres utilisateurs, avec les pseudonymes de chaque paire d'amis.
SELECT u1.pseudo AS utilisateur1, u2.pseudo AS utilisateur2
FROM utilisateurs u1
JOIN ami a ON u1.uid = a.id_utilisateur_1
JOIN utilisateurs u2 ON a.id_utilisateur_2 = u2.uid;

--Requete 3 (avec une sous-requête corrélée): EXECUTE users_follow_groupe(VARCHAR);
--Retourner tous les utilisateurs qui suivent au moins un groupe dont le genre musical est "Rock".
SELECT u.pseudo FROM utilisateurs u 
WHERE EXISTS (
    SELECT 1
    FROM follow f
    JOIN groupe g ON f.id_utilisateur_suivi = g.uid
    JOIN genre g1 ON g.genre_musical = g1.id_genre
    WHERE f.id_utilisateur_suiveur = u.uid
    AND g1.nom_genre = 'Rock'
);

--Requete 4 (avec une sous requete dans le FROM):
--Renvoie le nom, le prénom et le nombre de concerts auxquels chaque personne a participé, triés par ordre décroissant du nombre de concerts.
SELECT p.nom, p.prenom, s.nb_concerts
FROM (
    SELECT personne.uid, COUNT(*) AS nb_concerts
    FROM personne
    JOIN participation ON personne.uid = participation.id_personne
    where participation.participe is TRUE
    GROUP BY personne.uid
) AS s
JOIN personne p ON s.uid = p.uid
ORDER BY s.nb_concerts DESC;

--Requete 5(avec une sous requete dans le WHERE)
--Trouver les id_avis et les notes des avis qui sont associés au mot-clé "Excellent"
SELECT a.id_avis, a.note
FROM avis a
WHERE a.id_avis IN (
    SELECT ma.id_avis
    FROM motcles_avis ma
    INNER JOIN motcles m ON ma.id_motcles = m.id_motcles
    WHERE m.motcles = 'Excellent'
);

-- Deux Requetes 6 (avec GROUP BY et HAVING)
--Retourne le nom du groupe et le nombre de concerts aux quels ils ont participé (au moins 2 concerts) ordonée du plus grand au plus petit nombre
SELECT g.nom_groupe, COUNT(DISTINCT c.id_concert) AS nombre_concerts
FROM groupe g
JOIN performe p ON p.id_groupe = g.uid
JOIN concert c ON c.id_concert = p.concert
GROUP BY g.uid, g.nom_groupe 
HAVING COUNT(c.id_concert) >= 2
ORDER BY nombre_concerts DESC;

--Retourne les noms des personnes et le nombre de followers qu'elles ont, en ne sélectionnant que les personnes ayant au moins 1 followers.
SELECT p.nom, COUNT(f.id_follow) AS followers_count
FROM personne p
LEFT JOIN follow f ON p.uid = f.id_utilisateur_suivi
GROUP BY p.nom
HAVING COUNT(f.id_follow) >= 1;


--Requete 7(impliquant le calcul de deux agrégats)
--La requête sélectionne les genres musicaux, la moyenne des prix, la somme des prix des concerts, 
--uniquement pour les genres ayant plus de 1 concerts.
SELECT g.nom_genre, AVG(c.prix) AS moyenne_prix_concert, SUM(c.prix) AS somme_prix_total
FROM genre g
JOIN concert c ON g.id_genre = c.genre
GROUP BY g.nom_genre
HAVING COUNT(c.id_concert) >=2;


--Requete 8 (avec LEFT JOIN)
--Retourne les noms des groupes de musique et leur moyenne d'avis, en ne sélectionnant que les groupes ayant une moyenne d'avis supérieure ou égale à 8.
SELECT g.nom_groupe, AVG(a.note) AS moyenne_avis
FROM groupe g
LEFT JOIN avis_groupe ag ON g.uid = ag.id_groupe
LEFT JOIN avis a ON ag.id_avis = a.id_avis
GROUP BY g.nom_groupe
HAVING AVG(a.note) >= 8;

--Requetes 9 (sous requete corrélées + aggrégation)
--Toutes les salles de concert qui n'ont jamais accueilli de concerts.
--Requete avec sous requete corrélées
SELECT *
FROM salledeconcert s
WHERE NOT EXISTS (
    SELECT *
    FROM concert c
    WHERE c.salle = s.uid
);
--Requete avec aggregation
SELECT s.*
FROM salledeconcert s
LEFT JOIN concert c ON c.salle = s.uid
GROUP BY s.uid
HAVING COUNT(c.id_concert) = 0;

--Requete 12 (avec les valeurs NULL)
-- sélectionne le genre de concert, compte le nombre total de concerts pour chaque genre
--et récupère la date de création la plus récente parmi les salles de concert associées pour chaque genre.
--(mettre quelques attribut "salle" dans la table de concert à NULL pour observer la difference)
ALTER TABLE concert ALTER COLUMN salle DROP NOT NULL; -- pour supprimer la contrainte de NULL
UPDATE concert SET salle = NULL WHERE date_concert < '2023-04-01'; -- mettre à NULL certaine valeur salle 

SELECT c.genre, COUNT(*) AS total_concerts, MAX(s.date_creation) AS derniere_salle
FROM concert AS c
JOIN salledeconcert AS s ON c.salle = s.uid
GROUP BY c.genre;

SELECT c.genre, COUNT(*) AS total_concerts, MAX(s.date_creation) AS derniere_salle
FROM concert AS c
LEFT JOIN salledeconcert AS s ON c.salle = s.uid
GROUP BY c.genre;

--Requetes 14 (requete récursive) EXECUTE chaine_ami(integer,integer);
--liste tous les amis d'un utilisateur, ainsi que les amis de ses amis

WITH RECURSIVE friend_network AS (
  SELECT uid, pseudo, 1 AS niveau
  FROM utilisateurs
  WHERE uid = 1

  UNION
  
  SELECT u.uid, u.pseudo, fn.niveau + 1
  FROM utilisateurs u
  INNER JOIN friend_network fn ON u.uid IN (SELECT id_utilisateur_2 FROM ami WHERE id_utilisateur_1 = fn.uid)
  WHERE fn.niveau < 3
)
SELECT uid, pseudo
FROM friend_network
ORDER BY uid;


--Requetes 15 (fenetrage)
--Retourne chaque concert avec les détails des salles de concert associées,le nombre total de concerts par salle et la moyenne des prix des concerts pour chaque salle :
SELECT
    c.nom_concert,
    c.date_concert,
    c.heure_concert,
    c.prix,
    s.nom_salle,
    s.adresse,
    COUNT(*) OVER (PARTITION BY s.uid) AS total_concerts_par_salle,
    AVG(c.prix) OVER (PARTITION BY s.uid) AS moyenne_prix_par_salle
FROM concert c
JOIN salledeconcert s ON c.salle = s.uid;

--Calcul la moyenne des prix des places de concerts pour chaque mois de 2023
SELECT
    EXTRACT(MONTH FROM date_concert) AS mois,
    AVG(prix) OVER (PARTITION BY EXTRACT(MONTH FROM date_concert)) AS prix_moyen
FROM concert
WHERE EXTRACT(YEAR FROM date_concert) = 2023
ORDER BY  mois;



--Requetes 17 EXECUTE morceaux_playlist(INTEGER)
--Donne les morceaux d'une playlist
SELECT M.titre, M.duree, M.artiste
FROM morceau M
INNER JOIN playlist_morceau PM ON M.id_morceau = PM.id_morceau
INNER JOIN playlist P ON PM.id_playlist = P.id_playlist
WHERE P.id_playlist = 1;

--Requete 18
--Donne le genre ayant le plus de sous-genre
WITH sous_genres_count AS (
    SELECT g.id_genre, COUNT(gs.id_sous_genre) AS nombre_sous_genres
    FROM genre AS g
    JOIN genre_sous_genre AS gs ON g.id_genre = gs.id_genre
    GROUP BY g.id_genre
)
SELECT g.nom_genre, sgc.nombre_sous_genres
FROM genre AS g
JOIN sous_genres_count AS sgc ON g.id_genre = sgc.id_genre
WHERE sgc.nombre_sous_genres = (
    SELECT MAX(nombre_sous_genres)
    FROM sous_genres_count
);


--Requete 19
--Trouver les concerts ayant la meilleure note moyenne basée sur les avis.
SELECT c.nom_concert, AVG(a.note) AS note_moyenne
FROM concert AS c
JOIN avis_concert AS ac ON c.id_concert = ac.id_concert
JOIN avis AS a ON ac.id_avis = a.id_avis
GROUP BY c.nom_concert
ORDER BY note_moyenne DESC
LIMIT 1;

--Requete 20 EXECUTE users_genre(VARCHAR)
--Trouver les utilisateurs qui suivent tous les groupes de musique d'un genre donné.
SELECT u.pseudo
FROM utilisateurs u
JOIN follow f ON u.uid = f.id_utilisateur_suiveur
JOIN groupe g ON f.id_utilisateur_suivi = g.uid
JOIN genre genre1 ON g.genre_musical = genre1.id_genre
WHERE genre1.nom_genre = 'Rock'
GROUP BY u.uid, u.pseudo
HAVING COUNT(DISTINCT g.uid) = (
    SELECT COUNT(*)
    FROM groupe g2
    JOIN genre genre2 ON g2.genre_musical = genre2.id_genre
    WHERE genre2.nom_genre = 'Rock'
);