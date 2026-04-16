import 'dart:math';
import 'package:flutter/material.dart';

// Stati dell'algoritmo basati sulla teoria neuroviscerale
enum FocusState {
  flow, // Verde: Eustress, alta SDHR
  preFatigue, // Giallo: Rigidità cardiaca iniziale
  distress, // Rosso: Pausa obbligatoria
  activePause, // Letargia: Richiede movimento (Caso 2)
  macroBreak, // Esaurimento: Seduta terminata (Caso 1)
}

class FocusProvider extends ChangeNotifier {
  // Configurazione della Sliding Window (MVP)
  static const int windowSize = 60; // 5 minuti a 1 dato ogni 5 sec
  final List<int> _hrWindow = [];

  FocusState _currentState = FocusState.flow;
  double _currentSDHR = 0.0;
  double _currentHRMean = 0.0;

  // Soglie Baseline (Verranno popolate dinamicamente nei primi 5 min)
  double _baselineSDHR = 0.0;
  double _baselineHR = 0.0;
  bool _isCalibrating = true;

  FocusState get currentState => _currentState;
  bool get isCalibrating => _isCalibrating;

  // Ingestione Dati (Chiamata ogni 5 secondi dal wearable simulator)
  void ingestHRData(
    int hr,
    int confidence,
    bool isMoving,
    double readinessMultiplier,
  ) {
    // 1. Denoising: Scarta dati inaffidabili o alterati da movimento fisico
    if (confidence < 2 || isMoving) return;

    // 2. Sliding Window Management
    if (_hrWindow.length >= windowSize) {
      _hrWindow.removeAt(0);
    }
    _hrWindow.add(hr);

    // Attendi dati sufficienti per calcoli statistici validi
    if (_hrWindow.length < windowSize) return;

    // 3. Calcolo Metriche
    _calculateMetrics();

    // 4. Calibrazione Iniziale (Crea la baseline dinamica)
    if (_isCalibrating) {
      _baselineSDHR = _currentSDHR;
      _baselineHR = _currentHRMean;
      _isCalibrating = false;
      notifyListeners();
      return;
    }

    // 5. Valutazione di Stato e Trigger
    _evaluateState(readinessMultiplier);
  }

  void _calculateMetrics() {
    double sum = 0;
    for (int hr in _hrWindow) {
      sum += hr;
    }
    _currentHRMean = sum / _hrWindow.length;

    double varianceSum = 0;
    for (int hr in _hrWindow) {
      varianceSum += pow(hr - _currentHRMean, 2);
    }
    _currentSDHR = sqrt(varianceSum / _hrWindow.length);
  }

  void _evaluateState(double rsMultiplier) {
    // Logica di Tolleranza basata sul Readiness Score (es. RS 50 -> tolleranza dimezzata)
    double allowedSDHRDrop = (_baselineSDHR * 0.20) * rsMultiplier;

    // CASO 2: Ipo-attivazione (Letargia / Disimpegno)
    if (_currentHRMean < (_baselineHR * 0.85) &&
        _currentSDHR < _baselineSDHR * 0.5) {
      _transitionTo(FocusState.activePause);
      return;
    }

    // CASO 1: Iper-attivazione Acuta (Cardiovascular Drift / Distress grave)
    if (_currentHRMean > (_baselineHR * 1.40) &&
        _currentSDHR < _baselineSDHR * 0.5) {
      _transitionTo(FocusState.macroBreak);
      return;
    }

    // Valutazione Flow e Fatica Standard
    if (_currentSDHR < (_baselineSDHR - allowedSDHRDrop)) {
      // Rigidità rilevata: se già in pre-fatica, passa a distress
      if (_currentState == FocusState.preFatigue) {
        _transitionTo(FocusState.distress);
      } else if (_currentState == FocusState.flow) {
        _transitionTo(FocusState.preFatigue);
      }
    } else {
      // Recupero della flessibilità cardiaca
      _transitionTo(FocusState.flow);
    }
  }

  void _transitionTo(FocusState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      notifyListeners(); // Scatena il Color Morphing e il feedback aptico sulla UI
    }
  }

  // Intervento dei Confondenti (EMA - Es. Caffeina)
  void applyCaffeineTolerance() {
    // Allarga le maglie di tolleranza per i successivi 90 minuti
    _baselineHR *= 1.15;
    _transitionTo(FocusState.flow);
  }
}
