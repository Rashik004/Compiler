drop table borrowed_book;
drop table members;
drop table all_book;
drop table Book_list;

CREATE TABLE members(
  member_id number(20),
  name varchar (20),
  phone varchar  (22),
  book_limit number (3),
  PRIMARY KEY (member_id)
);

DESCRIBE members;

CREATE TABLE Book_list(
	ISBN varchar(27),
	name varchar(50) NOT NULL,
  author1 varchar (30),
  author2 varchar (30) DEFAULT NULL,
  author3 varchar (30) DEFAULT NULL,
  pages number(5),
	category varchar(20) NOT NULL,
  privilege varchar(10),
  total_books number (4),
  comments varchar (30),
	PRIMARY KEY(ISBN)
);

DESCRIBE book_list;

CREATE TABLE all_book(
	ISBN varchar(27),
	barcode varchar (20),
  price number(20),
  buying_date date,
	PRIMARY KEY(barcode),
  FOREIGN KEY (ISBN) references Book_list(ISBN) on delete cascade
);

DESCRIBE all_book;

CREATE TABLE borrowed_book(
	barcode varchar (20),
	member_id number(30),
	borrow_date date,
  due_date date,
  fine number(5),
  renew_left number(2),
	FOREIGN KEY(barcode) references all_book(barcode),
  FOREIGN KEY(member_id) references members(member_id)
);

DESCRIBE borrowed_book;

CREATE OR REPLACE TRIGGER check_book_limit--checks whether a student can borrow another book or not
BEFORE UPDATE OR INSERT ON borrowed_book
FOR EACH ROW
DECLARE
  totalBorrow members.book_limit%type;
  bookLimit members.book_limit%type;
BEGIN
   SELECT count(member_id) INTO totalBorrow
   FROM borrowed_book
   WHERE borrowed_book.member_id=:new.member_id;

   SELECT book_limit INTO bookLimit
   FROM members
   WHERE member_id=:new.member_id;

   IF bookLimit-totalBorrow <1 THEN
      RAISE_APPLICATION_ERROR(-20000,'book limit is up');
    END IF;
END check_book_limit;
/

CREATE OR REPLACE TRIGGER check_book_availability--checks whether a book is available or not
BEFORE UPDATE OR INSERT ON borrowed_book
FOR EACH ROW
DECLARE
  totalBorrow Book_list.total_books%type;
  bookLimit Book_list.total_books%type;
  bookIsbn Book_list.isbn%type;
  BEGIN
    SELECT distinct isbn INTO bookIsbn
    FROM all_book a
    WHERE a.barcode= :new.barcode;

    SELECT count(isbn) INTO totalBorrow
    FROM all_book natural join borrowed_book
    WHERE isbn= bookIsbn;

   SELECT total_books INTO bookLimit
   FROM Book_list
   WHERE isbn=bookIsbn;

   IF bookLimit-totalBorrow <1 THEN
      RAISE_APPLICATION_ERROR(-20000,'No books left');
    END IF;
END book_availability;
/

INSERT INTO members VALUES (01,'RASHIK HASNAT', '+8801675013080',  5);
INSERT INTO members VALUES (02,'Zahan', '+880167501322',  5);
INSERT INTO members VALUES (03,'sun', '+880167420420',  5);
INSERT INTO members VALUES (04,'bipu', '+8801111111',  8);
INSERT INTO members VALUES (05,'fahim', '+88016333080',  3);

INSERT INTO Book_list (isbn, name,author1, pages, category, total_books) VALUES ('412','System Analysis and Design', 'Elias M.Awad', 524, 'cse', 13);
INSERT INTO Book_list (isbn, name,author1, pages, category, total_books) VALUES ('111','Data and Computer Communication', 'Stallings', 878, 'ece', 23);
INSERT INTO Book_list (isbn, name,author1, pages, category, total_books) VALUES ('999','Oxford English Dictionary', 'bastob real', 2222, 'english', 3);
INSERT INTO Book_list (isbn, name,author1, pages, category, total_books) VALUES ('422','data structure', 'schaums', 524, 'cse', 13);
INSERT INTO Book_list (isbn, name,author1, pages, category, total_books) VALUES ('098','electrical habijabi', 'theraja', 524, 'eee', 13);

INSERT INTO all_book VALUES ('412', '01', 420, '22-DEC-2007');
INSERT INTO all_book VALUES ('412', '02', 2520, '22-DEC-2007');
INSERT INTO all_book VALUES ('412', '03', 120, '22-DEC-2007');
INSERT INTO all_book VALUES ('412', '04', 420, '22-DEC-2007');

INSERT INTO all_book VALUES ('111', '05', 2520, '22-DEC-2007');
INSERT INTO all_book VALUES ('999', '06', 2220, '22-DEC-2007');
INSERT INTO all_book VALUES ('999', '07', 20, '22-DEC-2007');

INSERT INTO borrowed_book VALUES ( '01', 01, '22-SEP-2014','22-OCT-2014',0,3);
INSERT INTO borrowed_book VALUES ( '02', 02, '22-SEP-2014','22-OCT-2014',0,3);
INSERT INTO borrowed_book VALUES ( '06', 01, '22-SEP-2014','23-SEP-2014',0,3);
INSERT INTO borrowed_book VALUES ( '04', 04, '22-SEP-2014','22-SEP-2014',0,3);
INSERT INTO borrowed_book VALUES ( '05', 05, '22-SEP-2014','22-SEP-2014',0,3);

--function that returns the number of book borrowed by a given member_id
CREATE OR REPLACE FUNCTION total_borrowed_book( 
  memberID members.member_id%type) RETURN NUMBER IS
  total NUMBER;
BEGIN
  SELECT count(barcode) INTO total
  FROM borrowed_book
  WHERE member_id=memberID;
  RETURN total;
END total_borrowed_book;
/
show error

--prints all books borrowed by the given member id--named PL/SQL Block
SET SERVEROUTPUT ON
CREATE OR REPLACE PROCEDURE  member_details(
  memberID number) IS
    CURSOR memmberDetail IS
      SELECT bl.name, bb.borrow_date, bb.due_date, bb.renew_left
      FROM borrowed_book bb, all_book ab, book_list bl
      WHERE bb.barcode=ab.barcode AND ab.isbn=bl.isbn  AND bb.member_id= memberID;
      total_record number(22);
      memberRecord memmberDetail%ROWTYPE;
      counter integer;
BEGIN
  OPEN memmberDetail;
  SELECT count(barcode) INTO total_record
  FROM borrowed_book
  WHERE member_id=memberID;
  counter:=0;
LOOP
        FETCH memmberDetail INTO memberRecord;
        counter:=counter+1;
        EXIT WHEN counter > total_record;
       DBMS_OUTPUT.PUT_LINE('Book name: '|| memberRecord.name||' borrowing date: '||memberRecord.borrow_date||' due date: '||memberRecord.due_date);
      END LOOP;
      close memmberDetail;
END;
/

BEGIN
   member_details(01);
END;
/

SELECT name, total_borrowed_book(member_id)as ttb
FROM members;

--prints the name of people who've borrowed book
SELECT DISTINCT name 
FROM members
WHERE member_id IN(
  SELECT member_id
  FROM borrowed_book
  );
--prints name of all borrowed book and name of the borrower
SELECT m.name, bl.name
FROM members m, all_book ab, book_list bl, borrowed_book bb
WHERE bb.barcode=ab.barcode AND ab.isbn=bl.isbn AND bb.member_id=m.member_id;

--prints name and total borrowed book of all the borrowers
SELECT  m.name,count(bb.barcode) as total_borrow
FROM borrowed_book bb,members m
WHERE bb.member_id=m.member_id
GROUP BY m.name
ORDER BY total_borrow DESC;

--prints the total number of borrowed book by the library
SELECT count(barcode) as total_borrowed
FROM borrowed_book;

--prints the isbn of the mostly costly book
SELECT isbn 
FROM all_book
WHERE price in (SELECT  MAX(price)
FROM all_book);


commit;
