import asyncio
import threading
import logging
import time
from bleak import BleakScanner
from database.db import get_session
from database.models import User
from dashboard.state import app_state
from calculations.body_composition import get_all_metrics
from ble.broadcast_decoder import decode_okok_broadcast

logger = logging.getLogger(__name__)

def run_ble_workflow():
    async def _workflow():
        logger.info("BLE Worker: Escutando Broadcasters OKOK F-6988...")
        app_state.set_status("Suba na balança agora...")
        
        # Obter o usuário selecionado no BD para cálculos precisos
        user_height = 175
        user_age = 35
        user_sex = 'M'
        user_act = 'moderate'
        user_waist = None
        user_hip = None
        
        try:
            from database.db import SessionLocal
            db = SessionLocal()
            try:
                user = db.query(User).filter(User.is_active == True).first()
                if user:
                    user_height = user.height_cm
                    user_age = user.age
                    user_sex = user.sex
                    user_act = user.activity_level
                    user_waist = user.waist_cm
                    user_hip = user.hip_cm
            finally:
                db.close()
        except Exception as e:
            logger.error(f"Erro ao buscar usuário para Worker BLE: {e}")
        
        stop_event = asyncio.Event()

        def detection_callback(device, advertisement_data):
            if app_state.ble_status == "Finalizado":
                return
                
            mfg_data = advertisement_data.manufacturer_data
            if not mfg_data:
                return
                
            for company_id, data in mfg_data.items():
                decoded = decode_okok_broadcast(company_id, data, device.address)
                if decoded:
                    app_state.set_status(f"Conectado (Broadcast {device.address[-5:]})...", device_name="Chipsea/OKOK Scale")
                    
                    weight = decoded["weight_kg"]
                    impedance = decoded["impedance"]
                    is_stable = decoded["is_stable"]
                    
                    # Update state live
                    app_state.update_weight(weight, stable=is_stable)
                    
                    if decoded["is_final_bia"] and impedance:
                        app_state.update_impedance(impedance)
                        metrics = get_all_metrics(weight, user_height, user_age, user_sex, impedance, user_act,
                                                  waist_cm=user_waist, hip_cm=user_hip)
                        app_state.set_metrics(metrics)
                        
                        logger.info(f"Medição finalizada: {weight}kg | {impedance}ohm")
                        app_state.set_status("Finalizado")
                        stop_event.set()
                        return
                    else:
                        # Fallback calculates without impedance for live preview
                        metrics = get_all_metrics(weight, user_height, user_age, user_sex, None, user_act,
                                                  waist_cm=user_waist, hip_cm=user_hip)
                        app_state.set_metrics(metrics)

        scanner = BleakScanner(detection_callback=detection_callback)
        await scanner.start()
        
        try:
            # Tempo máximo aguardando alguém subir na balança e concluir
            await asyncio.wait_for(stop_event.wait(), timeout=60.0)
        except asyncio.TimeoutError:
            if app_state.ble_status != "Finalizado":
                app_state.set_status("Desconectado")
                app_state.set_scan_error("Timeout: Nenhuma medição finalizada em 60s.")
                
        await scanner.stop()

    try:
        asyncio.run(_workflow())
    except Exception as e:
        logger.error(f"Erro fatal no BLE Worker: {e}", exc_info=True)
        app_state.set_status("Desconectado")
        app_state.set_scan_error("Erro de execução do listener.")

def start_ble_measurement_thread():
    app_state.reset()
    t = threading.Thread(target=run_ble_workflow, daemon=True)
    t.start()
