package tn.esprit.spring.Services.Interfaces;

import tn.esprit.spring.Entity.Bloc;

import java.util.List;

public interface IBlocService {
    List<Bloc> retrieveAllBlocs();
    Bloc addBloc(Bloc b);
    Bloc updateBloc (Bloc c);
    Bloc retrieveBloc (long idBloc);
}
