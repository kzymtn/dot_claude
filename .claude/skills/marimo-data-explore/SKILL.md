# marimo-data-explore

Discover all data assets (DataFrames, SQL tables, database connections, variables) in a **running** marimo session via MCP, then generate targeted exploration and visualization cells and append them to the notebook source file.

## When to Use

- User says "explore the data in my notebook" or "add EDA cells"
- User wants to understand what data is available in a running session before writing analysis code
- After loading data, user wants auto-generated summaries, distributions, and correlation views

## Workflow

### Step 1 — Discover session

Call `get_active_notebooks`. Select the session (auto if single, ask if multiple).

### Step 2 — Inventory all data assets

Call in parallel:

1. `get_tables_and_variables(session_id, variable_names=[])` — all variables with types and metadata
2. `get_database_tables(session_id)` — SQL/database connections and their schemas

From `get_tables_and_variables`, separate:
- **DataFrames / table-like objects**: pandas DataFrame, polars DataFrame, numpy ndarray, etc. — capture column names, dtypes, row count
- **Scalar / non-tabular variables**: int, float, str, list, dict — note for reference but do not generate EDA cells for these
- **Model objects** (sklearn, PyTorch, etc.): note but skip EDA

From `get_database_tables`, capture:
- Connection name, database name, schema, table names
- Column metadata if available

### Step 3 — Identify the existing cell boundary

Call `get_lightweight_cell_map` to know where the notebook currently ends (last cell ID and line count). New cells will be appended after the last existing cell.

Also call `get_marimo_rules` to refresh best practices before writing any code.

### Step 4 — Generate exploration cells

For **each DataFrame / table-like variable** identified in step 2, generate a set of marimo cells following the rules below.

#### Required cell: Shape and schema

```python
@app.cell
def _(mo, <varname>):
    mo.md(f"""
    ### `{varname}` — shape: {<varname>.shape}, columns: {list(<varname>.columns)}
    """)
    return
```

#### Required cell: Head preview

```python
@app.cell
def _(<varname>):
    return (<varname>.head(10),)
```

#### Conditional cell: Descriptive statistics (for numeric columns)

Only include if the DataFrame has at least one numeric column:

```python
@app.cell
def _(<varname>):
    return (<varname>.describe(),)
```

#### Conditional cell: Missing value summary

Only include if any column has nulls (infer from dtype or column metadata):

```python
@app.cell
def _(mo, <varname>):
    null_counts = <varname>.isnull().sum()
    null_pct = (null_counts / len(<varname>) * 100).round(1)
    summary = null_counts[null_counts > 0].to_frame("nulls")
    summary["pct"] = null_pct
    return (mo.ui.table(summary.reset_index()),)
```

#### Conditional cell: Distribution chart (for numeric columns, max 6 columns)

Use `mo.ui.altair_chart` or `altair` if available in the session (check imports from `get_cell_runtime_data` if needed); otherwise use `matplotlib`:

```python
@app.cell
def _(<varname>):
    import altair as alt
    numeric_cols = <varname>.select_dtypes("number").columns.tolist()[:6]
    chart = alt.Chart(<varname>).mark_bar().encode(
        x=alt.X(alt.repeat(), bin=True),
        y="count()",
    ).repeat(numeric_cols).properties(width=200, height=150)
    return (chart,)
```

#### Conditional cell: Correlation heatmap (>= 3 numeric columns)

```python
@app.cell
def _(<varname>):
    import altair as alt, pandas as pd
    corr = <varname>.select_dtypes("number").corr().stack().reset_index()
    corr.columns = ["var1", "var2", "corr"]
    chart = alt.Chart(corr).mark_rect().encode(
        x="var1:N", y="var2:N",
        color=alt.Color("corr:Q", scale=alt.Scale(scheme="redblue", domain=[-1, 1]))
    ).properties(width=300, height=300)
    return (chart,)
```

#### For SQL tables (from `get_database_tables`)

Generate a cell that queries a sample:

```python
@app.cell
def _(mo):
    return (mo.sql("""
    SELECT * FROM <table_name> LIMIT 10
    """),)
```

### Step 5 — Append cells to the source file

Locate the source `.py` file from the notebook path returned by `get_active_notebooks`.

Append the generated cells before the final `if __name__ == "__main__": app.run()` line, following `marimo-notebook` skill conventions:
- Each cell is a `@app.cell` decorated function
- Function parameters are the variables it consumes (explicit dependencies)
- Return tuple contains the output expression
- PEP 723 metadata is not changed

### Step 6 — Report

List the cells added and which variable each cell covers. Remind the user to save and let marimo hot-reload, or manually run the new cells.

## Rules

- **Inspect before writing**: never generate code without first calling `get_tables_and_variables` and `get_database_tables`. The actual runtime types and shapes determine which cells to generate.
- Respect existing imports: if `altair` is not imported in any existing cell (check via `get_cell_runtime_data` on import cells), use `matplotlib` as fallback or add an import cell first.
- Limit generated cells to avoid overwhelming the notebook — max 5 cells per DataFrame variable.
- Do not regenerate cells if an exploration section already exists for a variable (check `get_lightweight_cell_map` previews for existing EDA patterns).
- For polars DataFrames, replace `.isnull()` with `.null_count()` and `.select_dtypes()` with `.select(cs.numeric())` using `polars.selectors`.
- Always follow `marimo-notebook` skill cell conventions (explicit return, no top-level code outside cells).
