package tn.esprit.spring.controller;


import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.AllArgsConstructor;
import org.springframework.web.bind.annotation.*;
import tn.esprit.spring.Entity.Bloc;
import tn.esprit.spring.Services.Interfaces.IBlocService;

import java.util.List;
@RestController
@AllArgsConstructor
@RequestMapping("bloc")
@Tag(name="bloc controller")
public class bloccontroller {


    IBlocService iBlocService;
    @GetMapping("getAllblocs")
    public List<Bloc> retrieveAllBlocs() {
        return iBlocService.retrieveAllBlocs();
    }
    @PostMapping("/addbloc")
    public Bloc addBloc(@RequestBody Bloc b) {
        return iBlocService.addBloc(b);
    }

    public Bloc updateBloc(Bloc c) {
        return iBlocService.updateBloc(c);
    }
@GetMapping("/getId/{idBloc}")
    public Bloc retrieveBloc(@PathVariable long idBloc) {
        return iBlocService.retrieveBloc(idBloc);
    }






}
