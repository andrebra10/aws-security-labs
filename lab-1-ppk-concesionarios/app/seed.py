from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from auth import hash_password
from config import settings
from models import Client, FinancingRequest, User, Vehicle

VEHICLES = [
    ("SEAT", "León 1.5 TSI", 2024, 21900.00, 8500, "disponible"),
    ("Volkswagen", "T-Roc", 2024, 27500.00, 4200, "disponible"),
    ("Renault", "Clio", 2023, 14900.00, 21000, "disponible"),
    ("Peugeot", "3008", 2024, 31200.00, 1200, "reservado"),
    ("Toyota", "Corolla Hybrid", 2023, 24800.00, 15300, "disponible"),
    ("Kia", "Sportage", 2024, 28900.00, 6100, "disponible"),
    ("Hyundai", "Tucson", 2023, 27300.00, 18900, "vendido"),
    ("Skoda", "Octavia", 2024, 23600.00, 9800, "disponible"),
]

CLIENTS = [
    ("Laura Ibáñez Soto", "laura.ibanez@example.com", "+34 611 222 333", "Valencia"),
    ("Javier Molina Prat", "javier.molina@example.com", "+34 622 333 444", "Barcelona"),
    ("Nuria Campos Reyes", "nuria.campos@example.com", "+34 633 444 555", "Madrid"),
    ("Sergio Ferrer Vidal", "sergio.ferrer@example.com", "+34 644 555 666", "Sevilla"),
    ("Marta Lozano Aguirre", "marta.lozano@example.com", "+34 655 666 777", "Valencia"),
]

CORPORATE_USERS = [
    ("maria.gonzalez", "María González Ferrer", "comercial"),
    ("carlos.ruiz", "Carlos Ruiz Domenech", "administracion"),
]


def seed_data(db: Session) -> None:
    if db.query(Vehicle).count() == 0:
        for brand, model, year, price, mileage, status in VEHICLES:
            db.add(Vehicle(brand=brand, model=model, year=year, price=price,
                            mileage_km=mileage, status=status))
        db.commit()

    if db.query(Client).count() == 0:
        for full_name, email, phone, city in CLIENTS:
            db.add(Client(full_name=full_name, email=email, phone=phone, city=city))
        db.commit()

    if db.query(FinancingRequest).count() == 0:
        clients = db.query(Client).all()
        vehicles = db.query(Vehicle).all()
        now = datetime.utcnow()
        sample = [
            (clients[0], vehicles[0], 18500.00, 60, "aprobada"),
            (clients[1], vehicles[1], 24900.00, 72, "en_estudio"),
            (clients[2], vehicles[2], 12300.00, 48, "aprobada"),
            (clients[3], vehicles[3], 27950.00, 72, "pendiente_documentacion"),
        ]
        for client, vehicle, amount, term, status in sample:
            db.add(FinancingRequest(client_id=client.id, vehicle_id=vehicle.id,
                                     amount=amount, term_months=term, status=status,
                                     created_at=now - timedelta(days=term % 20)))
        db.commit()

    if db.query(User).count() == 0:
        for username, full_name, role in CORPORATE_USERS:
            db.add(User(username=username, full_name=full_name, role=role,
                        password_hash=hash_password(username + "-not-a-real-password")))
        db.commit()

    # Dev-mode convenience login for the developer team, seeded from the
    # same environment variables that end up in the leaked .env file.
    if settings.is_dev and settings.DEV_USERNAME and settings.DEV_PASSWORD:
        existing = db.query(User).filter_by(username=settings.DEV_USERNAME).first()
        if existing is None:
            db.add(User(
                username=settings.DEV_USERNAME,
                full_name="Pepe (Desarrollador)",
                role="desarrollo",
                password_hash=hash_password(settings.DEV_PASSWORD),
            ))
            db.commit()
