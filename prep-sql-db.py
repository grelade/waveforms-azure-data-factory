import pyodbc
import struct
from azure.identity import DefaultAzureCredential 

print

sqlname = 'waveform-sql-server'
dbname = 'waveform_db'
connection_string = f"Driver={{ODBC Driver 18 for SQL Server}};Server=tcp:{sqlname}.database.windows.net,1433;Database={dbname};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30"

print(connection_string)

credential = DefaultAzureCredential(exclude_interactive_browser_credential=False)
token_bytes = credential.get_token("https://database.windows.net/.default").token.encode("UTF-16-LE")
token_struct = struct.pack(f'<I{len(token_bytes)}s', len(token_bytes), token_bytes)
SQL_COPT_SS_ACCESS_TOKEN = 1256  # This connection option is defined by microsoft in msodbcsql.h
conn = pyodbc.connect(connection_string, attrs_before={SQL_COPT_SS_ACCESS_TOKEN: token_struct})

with get_conn() as conn:
    cursor = conn.cursor()
    output = cursor.execute("CREATE USER [waveform-df] FROM EXTERNAL PROVIDER; ALTER ROLE db_owner ADD MEMBER [waveform-df]")
    print(output)