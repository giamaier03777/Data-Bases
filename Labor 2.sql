-- Sub a: tabel cu PK simpla 
CREATE TABLE Organisatoren (
    id_organisator INT IDENTITY(1,1) PRIMARY KEY,
    organisator_name TEXT NOT NULL,
    organisator_email TEXT NOT NULL,
    organisator_telefon TEXT
);

-- Sub a: tabel cu PK simpla 
CREATE TABLE Veranstaltungen (
    id_veranstaltung INT IDENTITY(1,1) PRIMARY KEY,
    veranstaltungsname TEXT NOT NULL,
    startdatum DATE NOT NULL,
    enddatum DATE NOT NULL
);

-- Sub a: tabel cu PK compusa + FK 
CREATE TABLE Organisatoren_Veranstaltungen (
    id_organisator INT,
    id_veranstaltung INT,
    PRIMARY KEY (id_organisator, id_veranstaltung), 
    FOREIGN KEY (id_organisator) REFERENCES Organisatoren(id_organisator),
    FOREIGN KEY (id_veranstaltung) REFERENCES Veranstaltungen(id_veranstaltung)
);


-- Sub b: date pt tabel Organisatoren
INSERT INTO Organisatoren (organisator_name, organisator_email, organisator_telefon)
VALUES
('Organizator TEDx', 'organizer@tedxcluj.ro', '0745678567');

-- Sub b: date pt tabel Veranstaltungen
INSERT INTO Veranstaltungen (veranstaltungsname, startdatum, enddatum)
VALUES
('TEDx Eroilor', '2024-11-11', '2024-11-11');

-- Sub b: date pt tabel Organisatoren_Veranstaltungen
INSERT INTO Organisatoren_Veranstaltungen (id_organisator, id_veranstaltung)
VALUES
(1, 1); 

-- Sub c: FK invalida
INSERT INTO Organisatoren_Veranstaltungen (id_organisator, id_veranstaltung)
VALUES
(99, 1);


-- Sub d: modificare prin conditie compusa cu AND
UPDATE Organisatoren
SET organisator_email = 'newemail@tedxcluj.ro'
WHERE organisator_name = 'Organizator TEDx' AND organisator_telefon IS NOT NULL;

-- Sub d: stergere prin IN
DELETE FROM Veranstaltungen
WHERE id_veranstaltung IN (2, 3, 4); 

-- Sub d: modificare prin BETWEEN pt tot din noiembrie
UPDATE Veranstaltungen
SET veranstaltungsname = 'Eveniment Actualizat'
WHERE startdatum BETWEEN '2024-11-01' AND '2024-11-30'; 

-- Sub d: cautare cu LIKE (cine are tedx in mail)
SELECT * FROM Organisatoren
WHERE organisator_email LIKE '%tedx%'; 

--2
-- Lista participantilor la TEDx Eroilor de peste 25 de ani
SELECT T.teilnehmer_name, T.age, V.veranstaltungsname
FROM Teilnehmer T
JOIN Tickets Ti ON T.id_teilnehmer = Ti.teilnehmer_id
JOIN Veranstaltungen V ON Ti.veranstaltung_id = V.id_veranstaltung
WHERE V.veranstaltungsname = 'TEDx Eroilor' AND T.age > 25;

-- Lista organizatorilor si evenimentelor incluzand organizatorii fara evenimente 
SELECT O.organisator_name, V.veranstaltungsname
FROM Organisatoren O
LEFT OUTER JOIN Organisatoren_Veranstaltungen OV ON O.id_organisator = OV.id_organisator
LEFT OUTER JOIN Veranstaltungen V ON OV.id_veranstaltung = V.id_veranstaltung;

-- Organizatorii care participa la toate evenimentele disponibile
SELECT organisator_name
FROM Organisatoren
WHERE id_organisator = ALL (SELECT id_organisator FROM Organisatoren_Veranstaltungen);

-- Evenimentele la care participa orice organizator cu email care contine 'cluj.ro'
SELECT veranstaltungsname
FROM Veranstaltungen
WHERE id_veranstaltung = ANY (
    SELECT OV.id_veranstaltung
    FROM Organisatoren O
    JOIN Organisatoren_Veranstaltungen OV ON O.id_organisator = OV.id_organisator
    WHERE O.organisator_email LIKE '%cluj.ro%'
);

-- Nr de evenimente organizate de fiecare organizator
SELECT O.organisator_name, COUNT(V.id_veranstaltung) AS total_evenimente
FROM Organisatoren O
JOIN Organisatoren_Veranstaltungen OV ON O.id_organisator = OV.id_organisator
JOIN Veranstaltungen V ON OV.id_veranstaltung = V.id_veranstaltung
GROUP BY O.organisator_name;

-- Organizatorii care au sponsorizari de peste 7000
SELECT S.sponsor_name, SUM(SV.beitragssumme) AS total_sponsorizare
FROM Sponsoren S
JOIN Sponsoren_Veranstaltungen SV ON S.id_sponsor = SV.id_sponsor
GROUP BY S.sponsor_name
HAVING SUM(SV.beitragssumme) > 7000;

-- Lista tuturor locatiilor unice pt evenimente
SELECT DISTINCT standort_name
FROM Standorte;

-- Lista tuturor organizatorilor si sponsorilor
SELECT organisator_name AS name FROM Organisatoren
UNION
SELECT sponsor_name AS name FROM Sponsoren;

-- Organizatorii care nu au participat la evenimentul Techsylvania
SELECT organisator_name
FROM Organisatoren
WHERE id_organisator NOT IN (
    SELECT OV.id_organisator
    FROM Organisatoren_Veranstaltungen OV
    JOIN Veranstaltungen V ON OV.id_veranstaltung = V.id_veranstaltung
    WHERE V.veranstaltungsname = 'Techsylvania'
);

-- Primii 3 participanți cu varsta cea mai mare
SELECT TOP 3 teilnehmer_name, age
FROM Teilnehmer
ORDER BY age DESC;

-- Organizatorii care au participat la TEDx dar nu si la Techsylvania
SELECT O.organisator_name
FROM Organisatoren O
JOIN Organisatoren_Veranstaltungen OV ON O.id_organisator = OV.id_organisator
JOIN Veranstaltungen V ON OV.id_veranstaltung = V.id_veranstaltung
WHERE V.veranstaltungsname = 'TEDx Eroilor'

EXCEPT

SELECT O.organisator_name
FROM Organisatoren O
JOIN Organisatoren_Veranstaltungen OV ON O.id_organisator = OV.id_organisator
JOIN Veranstaltungen V ON OV.id_veranstaltung = V.id_veranstaltung
WHERE V.veranstaltungsname = 'Techsylvania';

-- Organizatorii care au participat si la TEDx Eroilor si la Techsylvania
SELECT O.organisator_name
FROM Organisatoren O
JOIN Organisatoren_Veranstaltungen OV ON O.id_organisator = OV.id_organisator
JOIN Veranstaltungen V ON OV.id_veranstaltung = V.id_veranstaltung
WHERE V.veranstaltungsname = 'TEDx Eroilor'

INTERSECT

SELECT O.organisator_name
FROM Organisatoren O
JOIN Organisatoren_Veranstaltungen OV ON O.id_organisator = OV.id_organisator
JOIN Veranstaltungen V ON OV.id_veranstaltung = V.id_veranstaltung
WHERE V.veranstaltungsname = 'Techsylvania';


DELETE FROM Veranstaltungen
WHERE id_veranstaltung IN (2, 3, 4); 
