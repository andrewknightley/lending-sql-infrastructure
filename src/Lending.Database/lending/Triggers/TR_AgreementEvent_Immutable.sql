CREATE TRIGGER [lending].[TR_AgreementEvent_Immutable]
ON [lending].[AgreementEvent]
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 51000, 'Agreement events are immutable. Append a new business fact instead.', 1;
END;
