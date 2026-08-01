from fastapi import APIRouter, Depends, Form, Request
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session

from auth import get_current_user, require_login, verify_password
from database import get_db
from models import Client, FinancingRequest, User, Vehicle
from templating import render

router = APIRouter()


@router.get("/")
def landing(request: Request, db: Session = Depends(get_db)):
    featured = db.query(Vehicle).filter(Vehicle.status == "disponible").limit(4).all()
    return render(request, "landing.html", featured_vehicles=featured)


@router.get("/vehiculos")
def vehicles_public(request: Request, db: Session = Depends(get_db)):
    vehicles = db.query(Vehicle).order_by(Vehicle.brand).all()
    return render(request, "vehicles.html", vehicles=vehicles)


@router.get("/login")
def login_form(request: Request, user: User | None = Depends(get_current_user)):
    if user:
        return RedirectResponse("/dashboard", status_code=303)
    return render(request, "login.html", error=None)


@router.post("/login")
def login_submit(
    request: Request,
    username: str = Form(...),
    password: str = Form(...),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter_by(username=username).first()
    if user is None or not verify_password(password, user.password_hash):
        return render(request, "login.html", error="Usuario o contraseña incorrectos.")

    request.session["user_id"] = user.id
    request.session["username"] = user.username
    return RedirectResponse("/dashboard", status_code=303)


@router.get("/logout")
def logout(request: Request):
    request.session.clear()
    return RedirectResponse("/", status_code=303)


@router.get("/dashboard")
def dashboard(request: Request, db: Session = Depends(get_db), user: User = Depends(require_login)):
    stats = {
        "vehicles": db.query(Vehicle).count(),
        "clients": db.query(Client).count(),
        "requests": db.query(FinancingRequest).count(),
    }
    return render(request, "dashboard.html", user=user, stats=stats)


@router.get("/clientes")
def clients_list(request: Request, db: Session = Depends(get_db), user: User = Depends(require_login)):
    clients = db.query(Client).order_by(Client.full_name).all()
    return render(request, "clients.html", clients=clients, user=user)


@router.get("/solicitudes")
def requests_list(request: Request, db: Session = Depends(get_db), user: User = Depends(require_login)):
    requests_ = db.query(FinancingRequest).order_by(FinancingRequest.created_at.desc()).all()
    return render(request, "requests.html", requests=requests_, user=user)
