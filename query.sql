CREATE USER [waveform-df] FROM EXTERNAL PROVIDER;
ALTER ROLE db_owner ADD MEMBER [waveform-df];
