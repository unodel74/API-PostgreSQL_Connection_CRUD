from flask import Flask, render_template, request, redirect, url_for
import psycopg2

app_3 = Flask(__name__)

# Configuración de la conexión a la base de datos PostgreSQL
db_config = {
    'dbname': 'Banco_Asturias',
    'user': 'postgres',
    'password': 'admin',
    'host': 'localhost',
    'port': '5434'
}

@app_3.route('/')
def index():
    conn = psycopg2.connect(**db_config)
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM usuarios")
    usuarios = cursor.fetchall()
    cursor.execute("SELECT * FROM acciones")
    acciones = cursor.fetchall()
    cursor.execute("SELECT * FROM bonos")
    bonos = cursor.fetchall()
    cursor.execute("SELECT * FROM depositos")
    depositos = cursor.fetchall()
    cursor.execute("SELECT * FROM operaciones")
    operaciones = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template('index.html', usuarios=usuarios, acciones=acciones, bonos=bonos, depositos=depositos, operaciones=operaciones)

@app_3.route('/add_user', methods=['POST'])
def add_user():
    nif = request.form['nif']
    nombre = request.form['nombre']
    
    conn = psycopg2.connect(**db_config)
    cursor = conn.cursor()
    cursor.execute("INSERT INTO usuarios (nif_cif, nombre) VALUES (%s, %s)", (nif, nombre))
    conn.commit()
    
    cursor.close()
    conn.close()
    
    return redirect(url_for('index'))

@app_3.route('/delete_user', methods=['POST'])
def delete_user():
    nif = request.form['nif']
    
    conn = psycopg2.connect(**db_config)
    cursor = conn.cursor()
    cursor.execute("DELETE FROM usuarios WHERE nif_cif = %s", (nif,))
    conn.commit()
    
    cursor.close()
    conn.close()
    
    return redirect(url_for('index'))

@app_3.route('/cartera_user', methods=['POST'])
def cartera_user():
    nif = request.form['nif']
    
    conn = psycopg2.connect(**db_config)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM total_cartera WHERE id_usuario = %s", (nif,))
    cartera = cursor.fetchall()
    conn.commit()
    
    cursor.close()
    conn.close()
    
    return render_template('cartera.html', cartera=cartera)

@app_3.route('/cartera_acciones', methods=['POST'])
def cartera_acciones():
    nif = request.form['nif']
    
    conn = psycopg2.connect(**db_config)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM cartera_acciones WHERE id_usuario = %s", (nif,))
    cartera_acciones = cursor.fetchall()
    conn.commit()
    
    cursor.close()
    conn.close()
    
    return render_template('cartera_acciones.html', cartera_acciones=cartera_acciones)

@app_3.route('/cartera_bonos', methods=['POST'])
def cartera_bonos():
    nif = request.form['nif']
    
    conn = psycopg2.connect(**db_config)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM cartera_bonos WHERE id_usuario = %s", (nif,))
    cartera_bonos = cursor.fetchall()
    conn.commit()
    
    cursor.close()
    conn.close()
    
    return render_template('cartera_bonos.html', cartera_bonos=cartera_bonos)

@app_3.route('/cartera_depos', methods=['POST'])
def cartera_depos():
    nif = request.form['nif']
    
    conn = psycopg2.connect(**db_config)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM cartera_depositos WHERE id_usuario = %s", (nif,))
    cartera_depos = cursor.fetchall()
    conn.commit()
    
    cursor.close()
    conn.close()
    
    return render_template('cartera_depos.html', cartera_depos=cartera_depos)

if __name__ == '__main__':
    app_3.run(debug=True)
