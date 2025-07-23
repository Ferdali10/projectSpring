package tn.esprit.spring.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import tn.esprit.spring.Entity.Bloc;

import java.util.List;


public interface BlocRepository extends JpaRepository<Bloc, Long> {

}
