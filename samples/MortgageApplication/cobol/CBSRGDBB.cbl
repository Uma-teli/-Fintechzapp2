       IDENTIFICATION DIVISION.
       PROGRAM-ID. CBSRGDBB.
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
        01 WS-ACCOUNT-NO-T PIC S9(18).
        01 WS-ACCOUNT-NAME PIC X(50).
        01 WS-PRINT PIC X(21) VALUE 'IS ALREADY REGISTERED'.
        01 WS-ACCOUNT-NAME1 PIC X(50).
        01 WS-PRINT1 PIC X(23) VALUE 'REGISTERED SUCCESSFULLY'.
        01 WS-ACCOUNT-STATUS  PIC X(10).
        01 WS-MESSAGE PIC X(100).
        01 WS-MESSAGE1 PIC X(100).
           EXEC SQL
           INCLUDE CBSMST
           END-EXEC.
           EXEC SQL
           INCLUDE SQLCA
           END-EXEC.
      *     COPY REGREQ.
      *     COPY REGRES.
      * 77 MESSAGES PIC X(35).
       LINKAGE SECTION.
       01 DFHCOMMAREA.
           02 CSRGREQ.
           COPY CSRGREQ.
           02 CSRGRES REDEFINES CSRGREQ.
           COPY CSRGRES.
      *     05 LS-ACCOUNT-NO PIC S9(18).
      *     05 LS-MESSAGES REDEFINES LS-ACCOUNT-NO PIC X(100).
      *     05  MESSAGES-DATA  PIC X(500).
      *    05 WS-INPUT
      *    05 WS-OUTPUT.
      *    COPY RESCPY.
      *    PROCESS STARTCMT
       PROCEDURE DIVISION.
           MOVE LOW-VALUES TO DCLCBS-ACCT-MSTR-DTL.
           MOVE ACCOUNT-NO TO WS-ACCOUNT-NO-T.
           MOVE SPACE TO CUSTOMER-NAME.
           MOVE SPACE TO SYS-DATE.
           MOVE SPACE TO SYS-TIME.
           COMPUTE CUSTOMER-ID = 0.
           PERFORM ACCT-VALID THRU ACCT-VALID-EXIT.
      *     MOVE SPACES TO LS-MESSAGES.
      *     MOVE MESSAGES TO LS-MESSAGES.
           EXEC CICS RETURN END-EXEC.
        ACCT-VALID.
      *     MOVE LOW-VALUES TO WS-ACCOUNT-NO.
      *     MOVE LS-ACCOUNT-NO TO WS-ACCOUNT-NO.
      *     MOVE WS-ACCOUNT-NO TO H1-ACCOUNT-NUMBER.

           COMPUTE H1-ACCOUNT-NUMBER = WS-ACCOUNT-NO-T
           DISPLAY "ACCT NO. FROM INPUT" H1-ACCOUNT-NUMBER
           EXEC SQL
            SELECT CURRENT TIME INTO :H1-ACCOUNT-STATUS FROM
            SYSIBM.SYSDUMMY1
            END-EXEC
            MOVE H1-ACCOUNT-STATUS TO SYS-TIME
            DISPLAY 'TIME'SYS-TIME

            EXEC SQL
            SELECT CURRENT DATE INTO :H1-ACCOUNT-STATUS FROM
            SYSIBM.SYSDUMMY1
            END-EXEC
            MOVE H1-ACCOUNT-STATUS TO SYS-DATE
            DISPLAY 'DATE'SYS-DATE
            EXEC SQL
           SELECT * INTO :DCLCBS-ACCT-MSTR-DTL
      *     ACCOUNT_NUMBER, ACCOUNT_STATUS, UPD_USERID, CUSTOMER_ID
      *     INTO
      *     :H1-ACCOUNT-NUMBER, :H1-ACCOUNT-STATUS, :H1-UPD-USERID,
      *     :H1-CUSTOMER-ID
           FROM CBS_ACCT_MSTR_DTL
           WHERE ACCOUNT_NUMBER=:H1-ACCOUNT-NUMBER
           END-EXEC
           MOVE LOW-VALUES TO WS-MESSAGE
           MOVE H1-ACCOUNT-NAME TO WS-ACCOUNT-NAME
           STRING WS-ACCOUNT-NAME DELIMITED BY SPACE
                  ' ' DELIMITED BY SIZE
                  WS-PRINT DELIMITED BY SIZE
            INTO WS-MESSAGE
           MOVE LOW-VALUES TO WS-MESSAGE1
           MOVE H1-ACCOUNT-NAME TO WS-ACCOUNT-NAME1
           STRING WS-ACCOUNT-NAME1 DELIMITED BY SPACE
                  ' ' DELIMITED BY SIZE
                  WS-PRINT1 DELIMITED BY SIZE
            INTO WS-MESSAGE1
           DISPLAY "MESS" WS-MESSAGE
           DISPLAY "NAME" WS-ACCOUNT-NAME
           DISPLAY "SQLCODE:" SQLCODE

           EVALUATE SQLCODE
            WHEN 0
             DISPLAY H1-ACCOUNT-NUMBER
             DISPLAY H1-UPD-USERID
             DISPLAY H1-ACCOUNT-STATUS
             DISPLAY H1-CUSTOMER-ID
             DISPLAY H1-PRODUCT-CODE
             DISPLAY 'ACCOUNT IS AVAILABLE'
             MOVE "SUCCESSFUL" TO MESSAGES
             MOVE H1-ACCOUNT-NAME TO CUSTOMER-NAME
             COMPUTE CUSTOMER-ID = H1-CUSTOMER-ID


             PERFORM ACCT-STATUS THRU ACCT-STATUS-EXIT
             DISPLAY 'MESSAGES:'
            WHEN 100
             MOVE "ACCOUNT DOES NOT EXIT WITH BANK" TO MESSAGES
             DISPLAY "MESSAGES:" MESSAGES
             EXEC CICS RETURN END-EXEC
            WHEN OTHER
             DISPLAY "SQLCODE1:" SQLCODE
             MOVE "SQL ERROR" TO MESSAGES
             DISPLAY "MESSAGES:" MESSAGES
             EXEC CICS RETURN END-EXEC
           END-EVALUATE.

        ACCT-VALID-EXIT.
           EXIT.
        ACCT-STATUS.
           EXEC SQL
           SELECT
           ACCOUNT_STATUS
           INTO
           :H1-ACCOUNT-STATUS
           FROM CBS_ACCT_MSTR_DTL
           WHERE ACCOUNT_NUMBER=:H1-ACCOUNT-NUMBER
           END-EXEC.
           EVALUATE SQLCODE
            WHEN 0
             DISPLAY H1-ACCOUNT-STATUS(1:6)
             MOVE H1-ACCOUNT-STATUS TO WS-ACCOUNT-STATUS
             DISPLAY WS-ACCOUNT-STATUS
             DISPLAY 'ACCOUNT STATUS IS FETCHED'
             MOVE "SUCCESSFUL" TO MESSAGES
             DISPLAY "MESSAGES:" MESSAGES
             PERFORM CHECK-ACCT-STATUS THRU CHECK-ACCT-STATUS-EXIT
            WHEN 100
             MOVE "NO RECORD FOUND" TO MESSAGES
             DISPLAY "MESSAGES:" MESSAGES
             EXEC CICS RETURN END-EXEC
            WHEN OTHER
             DISPLAY "SQLCODE2:" SQLCODE
             MOVE "SQL ERROR" TO MESSAGES
             DISPLAY "MESSAGES:" MESSAGES
             EXEC CICS RETURN END-EXEC
           END-EVALUATE.
        ACCT-STATUS-EXIT.
           EXIT.
        CHECK-ACCT-STATUS.
               DISPLAY 'CHECK STATUS PARA'
           EVALUATE WS-ACCOUNT-STATUS
              WHEN 'ACTIVE    '
               DISPLAY 'ALREADY REGISTERED'
               MOVE WS-MESSAGE TO MESSAGES
               EXEC CICS RETURN END-EXEC
              WHEN 'INACTIVE  '
               MOVE 'REGISTRATION STARTING' TO MESSAGES
               PERFORM REG-ACCT-STATS THRU REG-ACCT-STATS-EXIT
              WHEN 'OTHER'
               DISPLAY 'NOT Y OR N'
               MOVE 'PLEASE CONTACT BANK' TO MESSAGES
               EXEC CICS RETURN END-EXEC
           END-EVALUATE.
        CHECK-ACCT-STATUS-EXIT.
            EXIT.
        REG-ACCT-STATS.

           DISPLAY 'REGISTER PARA'
           EXEC SQL UPDATE CBS_ACCT_MSTR_DTL
            SET ACCOUNT_STATUS ='ACTIVE    ',
                UPD_USERID ='NAGARAJPK '
            WHERE ACCOUNT_NUMBER = :H1-ACCOUNT-NUMBER
           END-EXEC.
           DISPLAY SQLCODE
            MOVE WS-MESSAGE1 TO MESSAGES.
      **    MOVE "CUSTOMER REGISTERED SUCESSFULLY" TO MESSAGES.
        REG-ACCT-STATS-EXIT.
            EXIT.