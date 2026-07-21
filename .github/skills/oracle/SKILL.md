---
name: oracle
description: Automatically assists with Oracle database operations and performance tuning. Activates: When working with Oracle databases, schemas, tables, PL/SQL objects, queries, database development, or performance optimization
---

> [!CAUTION]
> **Auto-generated file** - Do not edit directly.
> Source: `plugins/oracle/skills/oracle/SKILL.md`
> Regenerate with: `npm run build`


# Oracle Database & Tuning Skill

This skill automatically activates when:
- Querying or analyzing Oracle database schemas and tables
- Creating or modifying PL/SQL objects (procedures, functions, packages, triggers)
- Executing SQL queries (SELECT, INSERT, UPDATE, DELETE)
- Understanding database relationships and dependencies
- Optimizing database performance with indexes and constraints
- Managing user-defined types and complex data structures
- Analyzing execution plans and query performance

## Capabilities

- **Schema Discovery**: Search and analyze tables, columns, and relationships
- **PL/SQL Development**: Create, modify, and debug stored procedures, functions, packages, and triggers
- **Query Execution**: Execute SELECT, UPDATE, DELETE queries and view results
- **Dependency Analysis**: Identify object dependencies and impact of changes
- **Performance Optimization**: Analyze indexes, constraints, and query performance
- **Type Management**: Work with user-defined types, object types, VARRAYs, and nested tables

## Oracle-Specific Formatting

### Naming Conventions (TASY Repository Standards)
- **Variable Suffixes**:
  - `_w` for working/local variables (e.g., `ds_erro_w`, `nr_sequencia_w`)
  - `_p` for parameters (e.g., `nr_atendimento_p`, `nm_usuario_p`)
  
- **Variable Prefixes by Type**:
  - `nr_` for numbers/sequences (e.g., `nr_sequencia`, `nr_atendimento`)
  - `ds_` for descriptions/strings (e.g., `ds_erro`, `ds_log`, `ds_parametros`)
  - `cd_` for codes/identifiers (e.g., `cd_estabelecimento`, `cd_pessoa_fisica`)
  - `dt_` for dates (e.g., `dt_atualizacao`, `dt_entrada`)
  - `ie_` for indicators/flags (e.g., `ie_status`, `ie_situacao`)
  - `qt_` for quantities (e.g., `qt_registro`, `qt_dias`)
  - `vl_` for values/amounts (e.g., `vl_total`, `vl_procedimento`)
  - `nm_` for names (e.g., `nm_usuario`, `nm_paciente`)

### Code Structure
- Use lowercase for SQL keywords (`create`, `select`, `where`, `from`)
- Use `create or replace` for procedures, functions, and packages
- Tab indentation for nested blocks
- Object names are case-insensitive: Oracle stores as uppercase, TASY uses lowercase in CREATE statements
- String concatenation uses `||`
- Line breaks: `chr(13) || chr(10)` or use utility package constants

### SQL and PL/SQL Syntax
- Use `%` for wildcard patterns in searches
- PL/SQL blocks structure: `BEGIN ... END;` with `/` terminator
- Comments: `--` for single line, `/* */` for multi-line headers
- String literals use single quotes: `'text'`
- Date handling: `TO_DATE('2026-01-15', 'YYYY-MM-DD')` or `to_char_tz` for timezone-aware
- Use `%type` and `%rowtype` for type-safe variable declarations

## Available MCP Tools

### Schema & Discovery Tools
- `mcp_oracle_get_table_schema` - Get schema for a specific table
- `mcp_oracle_get_tables_schema` - Get schema for multiple tables at once
- `mcp_oracle_search_tables_schema` - Search tables by name pattern
- `mcp_oracle_search_columns` - Find tables containing specific columns
- `mcp_oracle_get_related_tables` - Get foreign key relationships for a table
- `mcp_oracle_get_table_constraints` - Get constraints (PK, FK, unique, check)
- `mcp_oracle_get_table_indexes` - Get indexes for performance analysis

### PL/SQL Object Tools
- `mcp_oracle_get_pl_sql_objects` - Search for procedures, functions, packages, triggers
- `mcp_oracle_get_object_source` - Get source code of PL/SQL objects
- `mcp_oracle_execute_plsql_ddl` - Create or replace PL/SQL objects
- `mcp_oracle_execute_plsql_call` - Execute procedures or functions
- `mcp_oracle_get_dependent_objects` - Find objects that depend on another object

### Query Execution Tools
- `mcp_oracle_execute_select_query` - Execute SELECT queries
- `mcp_oracle_execute_update_query` - Execute UPDATE statements
- `mcp_oracle_execute_delete_query` - Execute DELETE statements

### Advanced Tools
- `mcp_oracle_get_user_defined_types` - Get custom type definitions
- `mcp_oracle_get_database_vendor_info` - Get database version and schema info
- `mcp_oracle_rebuild_schema_cache` - Rebuild schema cache after structural changes

## Best Practices

### Before Modifying Objects
1. Use `mcp_oracle_get_object_source` to review current implementation
2. Use `mcp_oracle_get_dependent_objects` to check impact and identify dependent objects
3. Test in development environment before production
4. Review existing code patterns in the codebase for consistency

### Query Development
1. Use `mcp_oracle_get_table_schema` to understand table structure and column types
2. Use `mcp_oracle_get_related_tables` to identify foreign key relationships for joins
3. Use `mcp_oracle_get_table_indexes` to optimize WHERE clauses and query performance
4. Use bind variables (`:parameter_name`) for dynamic SQL with proper binding

### Error Handling (TASY Repository Standards)
1. **Always use explicit exception handling** with descriptive context:
   ```plsql
   exception when others then
       ds_erro_w := substr(dbms_utility.format_error_backtrace || chr(13) || chr(10) || sqlerrm, 1, 4000);
       gravar_log_tasy(cd_log_p, ds_erro_w, nm_usuario_p);
   ```

2. **Capture comprehensive error information**:
   - Error message: `sqlerrm(sqlcode)` or `SQLERRM`
   - Stack trace: `dbms_utility.format_error_backtrace`
   - Call stack: `dbms_utility.format_call_stack`
   - Business context: Include relevant IDs and parameters

3. **Use autonomous logging**:
   - Use `PRAGMA AUTONOMOUS_TRANSACTION` for logging procedures
   - Ensures logs are committed even if main transaction rolls back

### Performance Optimization
1. Check indexes before writing complex queries
2. Consider foreign key relationships for efficient joins
3. Review constraints to understand data integrity rules
4. Use bind variables for repeated queries and prevent SQL injection
5. Use bulk operations (FORALL, BULK COLLECT) for large datasets
6. Avoid row-by-row processing when possible

## Common Workflows

### Database Schema Exploration
1. `mcp_oracle_search_tables_schema` - Find tables by pattern
2. `mcp_oracle_get_table_schema` - Get detailed structure
3. `mcp_oracle_get_related_tables` - Understand relationships
4. `mcp_oracle_get_table_constraints` - Review business rules

### PL/SQL Development (TASY Repository Standards)

**Package Header Documentation Template**:
```plsql
create or replace package package_name_pck as
/* +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Finalidade: [Clear description of package purpose and functionality]
-------------------------------------------------------------------------------------------------------------------
Locais de chamada direta:
[X] Objetos do dicionario [X] Tasy (HTML5) [ ] Portal [ ] Relatorios [ ] Outros:
-------------------------------------------------------------------------------------------------------------------
Pontos de atencao: [Important notes, dependencies, special considerations]
-------------------------------------------------------------------------------------------------------------------
Referencias: [Related objects, documents, or requirements]
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
```

**Standard Development Flow**:
1. `mcp_oracle_get_pl_sql_objects` - Check if object exists
2. Review existing patterns in repository for similar functionality
3. `mcp_oracle_execute_plsql_ddl` - Create/replace object using repository patterns
4. `mcp_oracle_execute_plsql_call` - Test execution with realistic data
5. `mcp_oracle_get_object_source` - Verify created code matches standards

**Coding Standards**:
1. **Variable Declarations**:
   - Group by type and purpose
   - Use meaningful names with standard prefixes (`nr_`, `ds_`, `cd_`, etc.)
   - Use `%type` for column-based variables
   - Use `%rowtype` for record variables

2. **Error Handling**:
   - Always include `EXCEPTION` block
   - Capture full context (error message, stack trace, parameters)
   - Log to appropriate log table
   - Use `pragma autonomous_transaction` for logging

3. **Commit Management**:
   - Explicit commits after DML operations
   - Consider transaction boundaries carefully
   - Use autonomous transactions only for logging

4. **Code Organization**:
   - Declare cursors before variables
   - Group related variables together
   - Place helper procedures/functions at package body top
   - Main procedures/functions follow

5. **Comments and Documentation**:
   - Package-level header with purpose, usage, and attention points
   - Inline comments for complex logic
   - Parameter descriptions in procedure headers
   - Change history for significant modifications

### Impact Analysis
1. `mcp_oracle_get_object_source` - Review object to change
2. `mcp_oracle_get_dependent_objects` - Check dependencies
3. Plan changes to minimize impact
4. Update objects with `mcp_oracle_execute_plsql_ddl`

### Data Analysis
1. `mcp_oracle_search_columns` - Find relevant columns
2. `mcp_oracle_execute_select_query` - Query data
3. Analyze results and refine queries
4. Document findings

## Notes

- Oracle object names are case-insensitive but stored as uppercase by Oracle database
- TASY codebase uses lowercase for object creation (e.g., `create or replace procedure my_proc`)
- Schema cache is automatically maintained; rebuild only when necessary