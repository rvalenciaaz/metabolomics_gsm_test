# tasks/visualize_and_report.py

def visualize_and_report(**kwargs):
    from db import session
    from models import AnalysisResults
    import pandas as pd
    import dash
    from dash import html, dcc
    import plotly.express as px

    # Fetch the latest analysis result
    result = session.query(AnalysisResults).order_by(AnalysisResults.id.desc()).first()
    fluxes = pd.DataFrame(list(result.fluxes.items()), columns=['Reaction_ID', 'Flux'])

    # Create interactive dashboard
    app = dash.Dash(__name__)

    app.layout = html.Div([
        html.H1('Metabolic Flux Analysis'),
        dcc.Graph(
            figure=px.bar(fluxes.nlargest(20, 'Flux'), x='Reaction_ID', y='Flux', title='Top 20 Flux-Carrying Reactions')
        )
    ])

    # Run the app (Note: In production, you may want to deploy the app differently)
    app.run_server(debug=False, port=8050)
