CREATE TABLE Movies (
    movieId INT PRIMARY KEY,
    movieName VARCHAR(255),
    genre NVARCHAR(50),
    ageRestriction INT,
    director NVARCHAR(100)
);

GO
CREATE FUNCTION checkAgeRestriction(
    @genre NVARCHAR(50),
    @ageRestriction INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @isValid BIT = 1
    IF @genre = 'Horror' AND (@ageRestriction IS NULL OR @ageRestriction < 18)
        SET @isValid = 0

    RETURN @isValid
END;
GO

GO
CREATE FUNCTION checkMovieName(
    @movieName VARCHAR(255)
)
RETURNS BIT
AS
BEGIN
    DECLARE @isValid BIT = 1 

    IF @movieName LIKE '%Hate%' OR
       @movieName LIKE '%Violence%' OR
       @movieName LIKE '%Drugs%' OR
       @movieName LIKE '%Sexual%' OR
       @movieName LIKE '%Discrimination%' OR
       @movieName LIKE '%Offensive%' OR
       @movieName LIKE '%Obscene%'
    BEGIN
        SET @isValid = 0
    END

    RETURN @isValid
END;
GO


CREATE PROCEDURE insertData
    @movieId INT,
    @movieName VARCHAR(255),
    @genre NVARCHAR(50),
    @ageRestriction INT,
    @director NVARCHAR(100)
AS
BEGIN
    IF dbo.checkMovieName(@movieName) = 0
    BEGIN
        PRINT 'Inappropriate name! The movie name cannot contain words like Hate, Violence, Drugs, Sexual, Discrimination, Offensive, Obscene.'
        RETURN
    END

    IF dbo.checkAgeRestriction(@genre, @ageRestriction) = 0
    BEGIN
        PRINT 'Inappropriate age restriction. Horror movies should not be attended by people under 18!'
        RETURN
    END

    INSERT INTO Movies (movieId, movieName, genre, ageRestriction, director)
    VALUES (@movieId, @movieName, @genre, @ageRestriction, @director)

    PRINT 'Data added successfully.'
END
GO

DELETE FROM Movies
EXEC insertData 1, 'Movie1', 'Horror', 18, 'Director1';
EXEC insertData 2, 'Movie2', 'Horror', 12, 'Director2';
EXEC insertData 3, 'Drugs and Vegas', 'Action', 18, 'Director3';

GO
CREATE FUNCTION getTicketSalesByEvent()
RETURNS TABLE
AS
RETURN (
    SELECT 
        veranstaltung_id,                  
        SUM(ticket_preis) AS TotalSales,  
        ROW_NUMBER() OVER (
            PARTITION BY veranstaltung_id 
            -- grupare pe baza de ID
            ORDER BY SUM(ticket_preis) DESC
        ) AS RankBySales                  
    FROM Tickets
    GROUP BY veranstaltung_id
);
GO

CREATE VIEW eventSalesInfo AS
WITH RankedEvents AS (
    SELECT 
        V.id_veranstaltung AS EventID,
        V.veranstaltungsname AS EventName,
        V.startdatum AS StartDate,
        V.enddatum AS EndDate,
        TS.TotalSales AS TotalSales,
        TS.RankBySales AS SalesRank
    FROM Veranstaltungen AS V
    LEFT JOIN getTicketSalesByEvent() AS TS 
        ON V.id_veranstaltung = TS.veranstaltung_id
)
SELECT 
    EventID,
    EventName,
    StartDate,
    EndDate,
    TotalSales
FROM RankedEvents;
GO

SELECT *
FROM eventSalesInfo
ORDER BY TotalSales DESC;

INSERT INTO Tickets
values(5, 500, 3, 2)

-- EX 3 
CREATE TABLE LogTable (
    logId INT IDENTITY PRIMARY KEY,
    actionDateTime DATETIME,
    actionType NVARCHAR(10),
    tableName NVARCHAR(50),
    affectedRows INT
);

GO
CREATE TRIGGER LogOperations
ON Movies
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @actionType NVARCHAR(10), @affectedRows INT;
    SET @affectedRows = @@ROWCOUNT;

    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @actionType = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @actionType = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM deleted)
        SET @actionType = 'DELETE';

    INSERT INTO LogTable (actionDateTime, actionType, tableName, affectedRows)
    VALUES (GETDATE(), @actionType, 'Movies', @affectedRows);
END;
GO

INSERT INTO Movies (movieId, movieName, genre, ageRestriction, director)
VALUES (4, 'Mystery Adventure', 'Mystery', 16, 'Director4');

DELETE FROM Movies
WHERE movieId = 4;

UPDATE Movies
SET movieName = 'Mystery Chronicles',
    genre = 'Thriller',
    ageRestriction = 18,
    director = 'DirectorX'
WHERE movieId = 4;

-- EX4
GO
CREATE PROCEDURE processMovies
AS
BEGIN
    DECLARE @movieId INT, @movieName NVARCHAR(255), @genre NVARCHAR(50), @ageRestriction INT, @director NVARCHAR(100);

    DECLARE movieCursor CURSOR FOR
    SELECT movieId, movieName, genre, ageRestriction, director FROM Movies;

    OPEN movieCursor;

    FETCH NEXT FROM movieCursor INTO @movieId, @movieName, @genre, @ageRestriction, @director;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Processing Movie: ' + @movieName;

        IF @genre = 'Horror' AND @ageRestriction < 18
        BEGIN
            PRINT 'WARNING: Horror movie "' + @movieName + '" has inappropriate age restriction!';
        END

        FETCH NEXT FROM movieCursor INTO @movieId, @movieName, @genre, @ageRestriction, @director;
    END;

    CLOSE movieCursor;
    DEALLOCATE movieCursor;
END;
GO

EXEC processMovies;

INSERT INTO Movies (movieId, movieName, genre, ageRestriction, director)
VALUES 
    (201, 'Scary Movie', 'Horror', 15, 'Director1'),
    (202, 'Happy Kids', 'Kids', 18, 'Director2');