from flask import Flask, render_template, request, jsonify
import subprocess

app = Flask(__name__)

# Route to serve the Posterizarr UI
@app.route('/')
def index():
    return render_template('PosterizarrUI.html')

# Route for handling the form submission
@app.route('/submit', methods=['POST'])
def submit():
    # Extract data from form fields
    link_path = request.form.get('linkPath')
    movie_show_name = request.form.get('movieShowName')
    create_season_poster = request.form.get('createSeasonPoster')
    season_name = request.form.get('seasonName')
    root_folder = request.form.get('rootFolder')
    library_name = request.form.get('libraryName')

    # Validate the required fields
    if not link_path or not root_folder or not library_name or (not movie_show_name and not create_season_poster):
        return jsonify({'error': 'Please fill in all required fields.'}), 400

    # Prepare arguments for the PowerShell script
    ps_script = "/config/Posterizarr.ps1"
    ps_args = [f'-Manual', f'-MPath "{link_path}"', f'-MRootFolder "{root_folder}"', f'-MLib "{library_name}"']

    if movie_show_name:
        ps_args.append(f'-MMovieShow "{movie_show_name}"')

    if create_season_poster:
        ps_args.append(f'-MSeasonPoster $true')
        if season_name:
            ps_args.append(f'-MSeason "{season_name}"')

    # Construct the full PowerShell command
    ps_command = f"pwsh {ps_script} {' '.join(ps_args)}"

    try:
        # Run the PowerShell script with the arguments
        result = subprocess.run(ps_command, shell=True, capture_output=True, text=True)

        if result.returncode != 0:
            return jsonify({'error': f'PowerShell script failed: {result.stderr}'}), 500

        # Return success if the script runs correctly
        return jsonify({'message': 'Asset creation started successfully!'}), 200

    except Exception as e:
        return jsonify({'error': f'An error occurred: {str(e)}'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
