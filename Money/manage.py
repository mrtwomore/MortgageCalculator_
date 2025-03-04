import os
from flask_migrate import Migrate
from flask.cli import FlaskGroup
from app import create_app
from app.models import User, Scenario
from app import db

app = create_app(os.getenv('FLASK_ENV') or 'default')
migrate = Migrate(app, db)

cli = FlaskGroup(app)

@cli.command("test")
def test():
    """Run the unit tests."""
    import unittest
    tests = unittest.TestLoader().discover('tests')
    unittest.TextTestRunner(verbosity=2).run(tests)

@cli.command("create_db")
def create_db():
    """Create the database."""
    db.create_all()

@cli.command("drop_db")
def drop_db():
    """Drop the database."""
    if input("Are you sure you want to drop all tables? (y/n): ").lower() == 'y':
        db.drop_all()
        print("Tables dropped.")
    else:
        print("Operation cancelled.")

@cli.command("seed_db")
def seed_db():
    """Seed the database with sample data."""
    # Create a test user
    user = User(username="demo", email="demo@example.com")
    user.set_password("demo123")
    db.session.add(user)
    
    # Create some sample scenarios
    scenarios = [
        Scenario(
            user_id=1,
            name="30 Year Fixed",
            principal=300000,
            annual_rate=3.5,
            years=30,
            frequency="monthly"
        ),
        Scenario(
            user_id=1,
            name="15 Year Fixed",
            principal=250000,
            annual_rate=2.75,
            years=15,
            frequency="monthly"
        )
    ]
    
    for scenario in scenarios:
        db.session.add(scenario)
    
    try:
        db.session.commit()
        print("Database seeded!")
    except Exception as e:
        db.session.rollback()
        print(f"Error seeding database: {e}")

if __name__ == '__main__':
    cli() 