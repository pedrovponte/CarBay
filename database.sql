DROP TABLE IF EXISTS "user";
DROP TABLE IF EXISTS Colour;
DROP TABLE IF EXISTS Brand;
DROP TABLE IF EXISTS Auction;
DROP TABLE IF EXISTS Image;
DROP TABLE IF EXISTS FavouriteSeller;
DROP TABLE IF EXISTS FavouriteAuction;
DROP TABLE IF EXISTS HelpMessage;
DROP TABLE IF EXISTS Rating;
DROP TABLE IF EXISTS Comment;
DROP TABLE IF EXISTS Report;
DROP TABLE IF EXISTS Bid;
DROP TABLE IF EXISTS Notification;


DROP TYPE IF EXISTS Scale CASCADE;
DROP TYPE IF EXISTS State CASCADE;


DROP TRIGGER IF EXISTS bid_rules ON Bid;
DROP TRIGGER IF EXISTS help_message_types ON HelpMessage;
DROP TRIGGER IF EXISTS rating_rules ON Rating;
DROP TRIGGER IF EXISTS delete_rules ON "user";
DROP TRIGGER IF EXISTS notify_rating ON Rating;
DROP TRIGGER IF EXISTS notify_help_message ON HelpMessage;
DROP TRIGGER IF EXISTS notify_favorite_sellers ON Auction;
DROP TRIGGER IF EXISTS notify_highest_bid ON Bid;
DROP TRIGGER IF EXISTS fts_auction_insert ON Auction;
DROP TRIGGER IF EXISTS fts_auction_update ON Auction;

DROP FUNCTION IF EXISTS bid_rules();
DROP FUNCTION IF EXISTS help_message_types();
DROP FUNCTION IF EXISTS rating_rules();
DROP FUNCTION IF EXISTS delete_rules();
DROP FUNCTION IF EXISTS notify_rating();
DROP FUNCTION IF EXISTS notify_help_message();
DROP FUNCTION IF EXISTS notify_favorite_sellers();
DROP FUNCTION IF EXISTS notify_highest_bid();
DROP FUNCTION IF EXISTS auction_search_update();



CREATE TABLE "user" (
    id                  SERIAL,
    name                VARCHAR(50) NOT NULL,
    username            VARCHAR(50) NOT NULL,
    email               VARCHAR(50) NOT NULL,
    password            VARCHAR(50) NOT NULL,
    image               VARCHAR(50) NOT NULL,
    banned              BOOLEAN DEFAULT FALSE NOT NULL,
    admin               BOOLEAN DEFAULT FALSE NOT NULL,

    CONSTRAINT UserPK PRIMARY KEY (id),
    CONSTRAINT UserUsernameUK UNIQUE (username),
    CONSTRAINT UserEmailUK UNIQUE (email)
);


CREATE TYPE Scale as ENUM (
  '1:8',
  '1:18',
  '1:43',
  '1:64'
);


CREATE TABLE Colour (
    id                      SERIAL,
    name                    VARCHAR(50) NOT NULL,

    CONSTRAINT ColourPK PRIMARY KEY (id),
    CONSTRAINT ColourNameUK UNIQUE (name)

);


CREATE TABLE Brand (
    id                      SERIAL,
    name                    VARCHAR(50) NOT NULL,

    CONSTRAINT BrandPK PRIMARY KEY (id),
    CONSTRAINT BrandNameUK UNIQUE (name)

);


CREATE TABLE Auction (
    id                       SERIAL,
    title                    VARCHAR(50) NOT NULL,
    description              VARCHAR(50) NOT NULL,
    startingPrice            DECIMAL NOT NULL,
    startDate                TIMESTAMP WITH TIME zone DEFAULT now() NOT NULL,
    finalDate                TIMESTAMP WITH TIME zone NOT NULL,
    suspend                  BOOLEAN DEFAULT FALSE NOT NULL,
    buyNow                   DECIMAL,
    scaleType                Scale NOT NULL,
    brandID                  INTEGER NOT NULL,
    colourID                 INTEGER NOT NULL,
    sellerID                 INTEGER,
    stitle                   TSVECTOR,
    sdescription             TSVECTOR,

    CONSTRAINT AuctionPK PRIMARY KEY (id),
    CONSTRAINT AuctionStartingPriceCK CHECK(startingPrice >= 1),
    CONSTRAINT AuctionStartDateCK CHECK(startDate >= now()),
    CONSTRAINT AuctionFinalDateCK CHECK(finalDate >= startDate),
    CONSTRAINT AuctionBuyNowCK CHECK (buyNow IS NULL or (buyNow IS NOT NULL and buyNow > startingPrice)),
    CONSTRAINT AuctionBrandFK FOREIGN KEY (brandID) REFERENCES Brand ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT AuctionColourFK FOREIGN KEY (colourID) REFERENCES Colour ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT AuctionSellerFK FOREIGN KEY (sellerID) REFERENCES "user" ON UPDATE CASCADE ON DELETE SET NULL
);


CREATE TABLE Image (
    id                      SERIAL,
    url                     VARCHAR(50) NOT NULL,
    auctionID               INTEGER NOT NULL,

    CONSTRAINT ImagePK PRIMARY KEY (id),
    CONSTRAINT ImageUrlUK UNIQUE (url),
    CONSTRAINT ImageAuctionFK FOREIGN KEY (auctionID) REFERENCES Auction ON UPDATE CASCADE ON DELETE CASCADE
);


CREATE TABLE FavouriteSeller (
    user1ID                 SERIAL,
    user2ID                 SERIAL,

    CONSTRAINT FavouriteSellerPK PRIMARY KEY (user1ID, user2ID),
    CONSTRAINT FavouriteSellerUser1FK FOREIGN KEY (user1ID) REFERENCES "user" ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FavouriteSellerUser2FK FOREIGN KEY (user2ID) REFERENCES "user" ON UPDATE CASCADE ON DELETE CASCADE
);


CREATE TABLE FavouriteAuction (
    userID                 SERIAL,
    auctionID              SERIAL,

    CONSTRAINT FavouriteAuctionPK PRIMARY KEY (userID,auctionID),
    CONSTRAINT FavouriteAuctionUserFK FOREIGN KEY (userID) REFERENCES "user" ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FavouriteAutionAuctionFK FOREIGN KEY (auctionID) REFERENCES Auction ON UPDATE CASCADE ON DELETE CASCADE
);


CREATE TABLE HelpMessage (
    id                      SERIAL,
    text                    VARCHAR(50) NOT NULL,
    dateHour                TIMESTAMP WITH TIME zone DEFAULT now() NOT NULL,
    read                    BOOLEAN DEFAULT FALSE NOT NULL,
    senderID                INTEGER,
    recipientID             INTEGER,
    
    CONSTRAINT HelpMessagePK PRIMARY KEY (id),
    CONSTRAINT HelpMessageDateLT CHECK (dateHour <= now()),
    CONSTRAINT HelpMessageSenderFK FOREIGN KEY (senderID) REFERENCES "user" ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT HelpMessageRecipientFK FOREIGN KEY (recipientID) REFERENCES "user" ON UPDATE CASCADE ON DELETE SET NULL
);


CREATE TABLE Rating (
    auctionID               SERIAL,
    winnerID                INTEGER,
    value                   INTEGER NOT NULL,
    dateHour                TIMESTAMP WITH TIME zone DEFAULT now() NOT NULL,
    comment                 VARCHAR(50) NOT NULL,

    CONSTRAINT RatingPK PRIMARY KEY (auctionID),
    CONSTRAINT RatingAuctionFK FOREIGN KEY (auctionID) REFERENCES Auction ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT RatingWinnerFK FOREIGN KEY (winnerID) REFERENCES "user" ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT RatingValueHT CHECK (value >= 1),
    CONSTRAINT RatingValueLT CHECK (value <= 5),
    CONSTRAINT RatingDateLT CHECK (dateHour <= now())
);


CREATE TYPE State as ENUM (
  'Waiting',
  'Discarded',
  'Banned'
);


CREATE TABLE Comment (
    id                      SERIAL,
    text                    VARCHAR(50) NOT NULL,
    dateHour                TIMESTAMP WITH TIME zone DEFAULT now() NOT NULL,
    authorID                INTEGER NOT NULL,
    auctionID               INTEGER NOT NULL,
    
    CONSTRAINT CommentPK PRIMARY KEY (id),
    CONSTRAINT CommentDateLT CHECK (dateHour <= now()),
    CONSTRAINT CommentAuthorFK FOREIGN KEY (authorID) REFERENCES "user" ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT CommentAuctionFK FOREIGN KEY (auctionID) REFERENCES Auction ON UPDATE CASCADE ON DELETE CASCADE
);


CREATE TABLE Report(
    id                        SERIAL,
    reason                    VARCHAR(50) NOT NULL,
    dateHour                  TIMESTAMP WITH TIME zone DEFAULT now() NOT NULL,
    reporterID                INTEGER,
    locationAuctionID         INTEGER DEFAULT NULL,
    locationCommentID         INTEGER DEFAULT NULL,
    locationRegisteredID      INTEGER DEFAULT NULL,
    stateType                 State DEFAULT 'Waiting' NOT NULL,

    CONSTRAINT ReportPK PRIMARY KEY (id),
    CONSTRAINT ReportReporterFK FOREIGN KEY (reporterID) REFERENCES "user" ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT ReportExclusiveORLocation CHECK (
        1 = (
            CASE WHEN locationAuctionID IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN locationCommentID IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN locationRegisteredID IS NOT NULL THEN 1 ELSE 0 END
        )
    ),
    CONSTRAINT ReportLocationAuctionFK FOREIGN KEY (locationAuctionID) REFERENCES Auction ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ReportLocationCommentFK FOREIGN KEY (locationCommentID) REFERENCES Comment ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ReportLocationRegisteredFK FOREIGN KEY (locationRegisteredID) REFERENCES "user" ON UPDATE CASCADE ON DELETE CASCADE
);


CREATE TABLE Bid (
    id                      SERIAL,
    value                   DECIMAL NOT NULL,
    dateHour                TIMESTAMP WITH TIME zone DEFAULT now() NOT NULL,
    authorID                INTEGER,
    auctionID               INTEGER NOT NULL,

    CONSTRAINT BidPK PRIMARY KEY (id),
    CONSTRAINT BidDateCK CHECK(dateHour <= now()),
    CONSTRAINT BidAuthorFK FOREIGN KEY (authorID) REFERENCES "user" ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT BidAuctionFK FOREIGN KEY (auctionID) REFERENCES Auction ON UPDATE CASCADE ON DELETE RESTRICT
);


CREATE TABLE Notification (
    id                      SERIAL,
    viewed                  BOOLEAN DEFAULT FALSE NOT NULL,
    dateHour                TIMESTAMP WITH TIME zone DEFAULT now() NOT NULL,
    recipientID             INTEGER NOT NULL,
    contextRating           INTEGER DEFAULT NULL,
    contextHelpMessage      INTEGER DEFAULT NULL,
    contextFavSeller        INTEGER DEFAULT NULL,
    contextBid              INTEGER DEFAULT NULL,
    contextFavAuction       INTEGER DEFAULT NULL,

    CONSTRAINT NotificationPK PRIMARY KEY (id),
    CONSTRAINT NotificationDateLT CHECK (dateHour <= now()),
    CONSTRAINT NotificationExclusiveORContext CHECK (
        1 = (
            CASE WHEN contextRating IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN contextHelpMessage IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN contextFavSeller IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN contextBid IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN contextFavAuction IS NOT NULL THEN 1 ELSE 0 END
        )
    ),
    CONSTRAINT NotificationRecipientIDFK FOREIGN KEY (recipientID) REFERENCES "user" ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT NotificationContextRatingFK FOREIGN KEY (contextRating) REFERENCES Auction ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT NotificationContextHelpMessageFK FOREIGN KEY (contextHelpMessage) REFERENCES HelpMessage ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT NotificationContextFavSellerFK FOREIGN KEY (contextFavSeller) REFERENCES "user" ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT NotificationContextBidFK FOREIGN KEY (contextBid) REFERENCES Auction ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT NotificationContextFavAuctionFK FOREIGN KEY (contextFavAuction) REFERENCES Auction ON UPDATE CASCADE ON DELETE CASCADE
);


------------------------------INDEXES------------------------------


CREATE INDEX auction_date ON auction USING btree (finalDate);

CREATE INDEX auction_buyNow ON auction USING btree (buyNow);

CREATE INDEX comment_auction ON comment USING hash (auctionID);

CREATE INDEX bid_value ON bid USING btree (auctionID, value);


------------------------------FUNCTIONS------------------------------


CREATE FUNCTION bid_rules() RETURNS TRIGGER AS
$BODY$
BEGIN
    IF EXISTS 
        (SELECT * 
        FROM bid 
        WHERE NEW.auctionID = bid.auctionID AND bid.value >= NEW.value)
    THEN 
    RAISE EXCEPTION 'A new bid must be higher than any other bids of the auction.';
    END IF;
    IF EXISTS 
        (SELECT 
            (SELECT startingPrice 
            FROM auction 
            WHERE auction.id = NEW.auctionID) AS startingPrice 
        FROM NEW 
        WHERE startingPrice > NEW.value)
    THEN 
    RAISE EXCEPTION 'A new bid must be higher than the starting price.';
    END IF;
    IF EXISTS 
        (SELECT * 
        FROM auction 
        WHERE auction.id = NEW.auctionID AND auction.sellerID = NEW.authorID)
    THEN 
    RAISE EXCEPTION 'The author of a new bid must not be the auction seller.';
    END IF;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;
 

CREATE FUNCTION help_message_types() RETURNS TRIGGER AS
$BODY$
BEGIN
    IF EXISTS 
        (SELECT 
            (SELECT admin 
            FROM "user" 
            WHERE "user".id = NEW.senderID) AS admin1,
            (SELECT admin 
            FROM "user" 
            WHERE "user".id = NEW.recipientID) AS admin2
        FROM NEW 
        WHERE NEW.senderID = NEW.recipientID OR admin1 = admin2)
    THEN 
    RAISE EXCEPTION 'In a HelpMessage, the Sender must be of a different type of the Recipient.';
    END IF;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;
 

CREATE FUNCTION rating_rules() RETURNS TRIGGER AS
$BODY$
BEGIN
    IF EXISTS 
        (SELECT finalDate FROM NEW, auction WHERE NEW.auctionID = auction.id AND finalDate > NOW())
        OR
        (SELECT * 
            FROM (SELECT bid.authorID, MAX(id) FROM bid WHERE NEW.auctionID = bid.auctionID) AS T
        WHERE T.authorID != NEW.authorID)
    THEN 
    RAISE EXCEPTION 'The registered user can only give a rating to an auction he won.';
    END IF;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;
 

CREATE FUNCTION delete_rules() RETURNS TRIGGER AS
$BODY$
BEGIN
    IF EXISTS 
        (SELECT auction.id FROM OLD, auction WHERE OLD.id = auction.sellerID AND finalDate > NOW())
    THEN 
    RAISE EXCEPTION 'A user can only delete its account if there are no active auctions where he is the seller.';
    END IF;
    IF EXISTS 
        (SELECT bid.id FROM OLD, bid, auction WHERE OLD.id = bid.authorID AND finalDate > NOW() AND auction.id = bid.auctionID)
    THEN 
    RAISE EXCEPTION 'A user can only delete its account if he is not the author of any highest bid.';
    END IF;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;
 

CREATE FUNCTION notify_rating() RETURNS TRIGGER AS 
$BODY$
BEGIN
    INSERT INTO notification (recipientId, contextRating)
    VALUES (
        (SELECT sellerID FROM auction WHERE auction.id = NEW.auctionID),
        NEW.auctionID
    );
END
$BODY$
LANGUAGE 'plpgsql';


CREATE FUNCTION notify_help_message() RETURNS TRIGGER AS 
$BODY$
BEGIN
    INSERT INTO notification (recipientId, contextHelpMessage)
    VALUES (NEW.recipientID, NEW.id);
END
$BODY$ 
LANGUAGE 'plpgsql';


CREATE FUNCTION notify_favorite_sellers() RETURNS TRIGGER AS 
$BODY$
BEGIN
    INSERT INTO notification (recipientId, contextFavSeller)
    VALUES 
    SELECT user1ID , NEW.id 
        FROM FavouriteSeller 
        WHERE FavouriteSeller.user2ID = NEW.sellerID;
END
$BODY$ 
LANGUAGE 'plpgsql';


CREATE FUNCTION notify_highest_bid() RETURNS TRIGGER AS 
$BODY$
BEGIN
    INSERT INTO notification (recipientId, contextBid)
    VALUES 
    SELECT authorID , OLD.auctionID 
        FROM OLD
        WHERE OLD.auctionID = NEW.auctionID
        ORDER BY OLD.value DESC
        LIMIT 1;
END
$BODY$ 
LANGUAGE 'plpgsql';


CREATE FUNCTION auction_search_update() RETURNS TRIGGER AS 
$BODY$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.stitle = to_tsvector('english', NEW.title);
        NEW.sdescription = to_tsvector('english', NEW.description);
    END IF;
    IF TG_OP = 'UPDATE' THEN
        IF NEW.title <> OLD.title THEN
            NEW.stitle = to_tsvector('english', NEW.title);
        END IF;
        IF NEW.description <> OLD.description THEN
            NEW.sdescription = to_tsvector('english', NEW.description);
        END IF;
    END IF;
    RETURN NEW;
END
$BODY$ 
LANGUAGE 'plpgsql';


------------------------------TRIGGERS------------------------------


CREATE TRIGGER bid_rules
    BEFORE INSERT ON bid
    FOR EACH ROW
    EXECUTE PROCEDURE bid_rules();


CREATE TRIGGER help_message_types
    BEFORE INSERT ON helpMessage
    FOR EACH ROW
    EXECUTE PROCEDURE help_message_types();


CREATE TRIGGER rating_rules
    BEFORE INSERT ON rating
    FOR EACH ROW
    EXECUTE PROCEDURE rating_rules();


CREATE TRIGGER delete_rules
    BEFORE INSERT ON "user"
    FOR EACH ROW
    EXECUTE PROCEDURE delete_rules();


CREATE TRIGGER notify_rating
    AFTER INSERT ON rating
    FOR EACH ROW
    EXECUTE PROCEDURE notify_rating();


CREATE TRIGGER notify_help_message
    AFTER INSERT ON helpMessage
    FOR EACH ROW
    EXECUTE PROCEDURE notify_help_message();


CREATE TRIGGER notify_favorite_sellers
    AFTER INSERT ON auction
    FOR EACH ROW
    EXECUTE PROCEDURE notify_favorite_sellers();


CREATE TRIGGER notify_highest_bid
    AFTER INSERT ON bid
    FOR EACH ROW
    EXECUTE PROCEDURE notify_highest_bid();


CREATE TRIGGER fts_auction_insert
    BEFORE INSERT ON auction
    FOR EACH ROW
    EXECUTE PROCEDURE auction_search_update();

CREATE TRIGGER fts_auction_update
    BEFORE UPDATE ON auction
    FOR EACH ROW
    EXECUTE PROCEDURE auction_search_update();