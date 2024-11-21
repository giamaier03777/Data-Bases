-- Sub a: tabel cu PK simpla (Organisatoren)
CREATE TABLE Organisatoren (
    id_organisator INT IDENTITY(1,1) PRIMARY KEY,
    organisator_name TEXT NOT NULL,
    organisator_email TEXT NOT NULL,
    organisator_telefon TEXT
);

-- Sub a: tabel cu PK simpla (Veranstaltungen)
CREATE TABLE Veranstaltungen (
    id_veranstaltung INT IDENTITY(1,1) PRIMARY KEY,
    veranstaltungsname TEXT NOT NULL,
    startdatum DATE NOT NULL,
    enddatum DATE NOT NULL
);

-- Sub a: tabel cu PK compusa + FK (Organisatoren_Veranstaltungen)
CREATE TABLE Organisatoren_Veranstaltungen (
    id_organisator INT,
    id_veranstaltung INT,
    PRIMARY KEY (id_organisator, id_veranstaltung), -- PK
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

-- Sub c: Fail la inserare - FK invalida- ID 99 nu exista in Org
INSERT INTO Organisatoren_Veranstaltungen (id_organisator, id_veranstaltung)
VALUES
(99, 1);


-- Sub d: modificare prin conditie compusa cu AND
UPDATE Organisatoren
SET organisator_email = 'newemail@tedxcluj.ro'
WHERE organisator_name = 'Organizator TEDx' AND organisator_telefon IS NOT NULL;

-- Sub d: stergere prin IN
DELETE FROM Veranstaltungen
WHERE id_veranstaltung IN (2, 3, 4); -- stergere evenimente 2,3,4

-- Sub d: modificare prin BETWEEN pt tot din noiembrie
UPDATE Veranstaltungen
SET veranstaltungsname = 'Eveniment Actualizat'
WHERE startdatum BETWEEN '2024-11-01' AND '2024-11-30'; 

-- Sub d: cautare cu LIKE (cine are tedx in mail)
SELECT * FROM Organisatoren
WHERE organisator_email LIKE '%tedx%'; 


--2
SELECT 
    O.organisator_name,
    V.veranstaltungsname
FROM 
    Organisatoren O
JOIN 
    Organisatoren_Veranstaltungen OV ON O.id_organisator = OV.id_organisator
JOIN 
    Veranstaltungen V ON OV.id_veranstaltung = V.id_veranstaltung
