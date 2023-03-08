#include "../include/ComSubExprEli.h"
#include <set>
#include <algorithm>

void ComSubExprEli::execute() {
    for (auto func: unit->get_functions()){
        if (func->getBlockList().empty()) continue;
        initial_map(func);
        compute_local_gen(func);
        compute_local_kill(func);
        compute_global_in_out(func);
        compute_global_common_expr(func);
    }
}

bool ComSubExprEli::is_valid_expr(Instruction *inst) {
    return !(inst->isVoid()||inst->isCall()||inst->isAlloc()||inst->isLOAD()||inst->isCMP()||inst->isZEXT());
}

void ComSubExprEli::initial_map(Function *f) {
    for (auto bb: f->getBlockList()){
        bb_in[bb] = std::set<Instruction*,cmp_inst>();
        bb_out[bb] = std::set<Instruction*,cmp_inst>();
        bb_gen[bb] = std::set<Instruction*,cmp_inst>();
        bb_kill[bb] = std::set<Instruction*,cmp_inst>();
    }
}

void ComSubExprEli::compute_local_gen(Function *f) {
    //std::cerr << "local expr\n";
    // for (auto bb: f->getBlockList()){
    //     //std::cerr << bb->get_name() << std::endl;
    //     std::vector<Instruction*> delete_list = {};  // instructions to be deleted
    //     auto head = bb->end();  //instructions in function f
    //     for (auto instr = head->getNext(); instr != head; instr = instr->getNext()){
    //         if (is_valid_expr(instr)){
    //             auto res = bb_gen[bb].insert(instr);
    //             // if (!res.second){  // instr already exists in bb_gen[bb]
    //             //     auto old_instr = bb_gen[bb].find(instr);
    //             //     //std::cerr << "local replace " << instr->print() << " with "<< (*old_instr)->print() << std::endl;
    //             //     instr->replace_all_use_with(*old_instr);  // use *old_instr to replace instr
    //             //     delete_list.push_back(instr);
    //             // }
    //             // else{
    //             //     //std::cerr << "insert " << instr->print() <<" into bb_gen\n";
    //             //     auto u_res = U.insert(instr);
    //             //     //if (u_res.second)
    //             //     //    std::cerr << "insert " << instr->print() <<" into U\n";
    //             // }
    //         }
    //     }
    //     for (auto instr: delete_list)
    //         // bb->delete_instr(instr);
    // }
}

void ComSubExprEli::compute_local_kill(Function *f) {
    for (auto bb: f->getBlockList()){
        // auto instrs = bb->get_instructions();
        // for (auto instr: instrs){
        //     if (is_valid_expr(instr)){
        //         bb_kill[bb].erase(instr);
        //     }
        // }
    }
}


void ComSubExprEli::compute_global_in_out(Function *f) {
    auto all_bbs = f->getBlockList();
    // auto entry = f->get_entry_block();
    // for (auto bb: all_bbs)
    //     if (bb != entry) bb_out[bb] = U;  //initialize
    // bb_out[entry] = std::set<Instruction*,cmp_expr>();  //empty set
    // bool change = true;
    // int iter_cnt = 1;
    // while (change){  //stop iteration if nothing changes
    //     iter_cnt++;
    //     change = false;
    //     for (auto bb: all_bbs){
    //         if (bb != entry){
    //             // std::cerr << "cur bb:" << bb->get_name() <<std::endl;
    //             std::set<Instruction*,cmp_expr> last_tmp;
    //             bool is_first = true;
    //             for (auto pred: bb->get_pre_basic_blocks()){  //bb_in[B] = intersect{bb_out[P]} for all P->B
    //                 //std::cerr << "pred bb:"<< pred->get_name() <<std::endl;
    //                 if (!is_first){
    //                     std::set<Instruction*,cmp_expr> this_tmp = {};
    //                     std::insert_iterator<std::set<Instruction*,cmp_expr>> it(this_tmp,this_tmp.begin());
    //                     std::set_intersection(last_tmp.begin(),last_tmp.end(),bb_out[pred].begin(),bb_out[pred].end(),it);
    //                     last_tmp = this_tmp;
    //                 }
    //                 else{
    //                     is_first = false;
    //                     last_tmp = bb_out[pred];
    //                 }
    //             }
    //             bb_in[bb] = last_tmp;

    //             // bb_OUT[B] = bb_gen[B] union (IN[B]-bb_kill[B])
    //             auto old_out_size = bb_out[bb].size();
    //             std::set<Instruction*,cmp_expr> tmp2 = {};
    //             std::insert_iterator<std::set<Instruction*,cmp_expr>> it(tmp2,tmp2.begin());
    //             std::set_difference(bb_in[bb].begin(),bb_in[bb].end(),bb_kill[bb].begin(),bb_kill[bb].end(),it);
    //             std::set<Instruction*,cmp_expr> tmp3 = {};
    //             std::insert_iterator<std::set<Instruction*,cmp_expr>> it2(tmp3,tmp3.begin());
    //             std::set_union(bb_in[bb].begin(), bb_in[bb].end(), bb_gen[bb].begin(), bb_gen[bb].end(), it);

    //             bb_out[bb] = tmp2;
    //             auto new_out_size = tmp2.size();
    //             if (old_out_size != new_out_size)
    //                 change = true;
    //         }
    //     }
    // }
}

void ComSubExprEli::compute_global_common_expr(Function *f) {
    //std::cerr << "global\n";
    std::set<Instruction*> delete_list = {};
    std::map<Instruction*,Instruction*> replace_map;
    auto all_bbs = f->getBlockList();
    // for (auto bb: all_bbs){
    //     //std::cerr << "cur bb:"<< bb->get_name() << std::endl;
    //     auto instrs = bb->get_instructions();
    //     for (auto instr : instrs) {
    //         if (is_valid_expr(instr)) {
    //             auto common_exp = bb_in[bb].find(instr);
    //             if (common_exp != bb_in[bb].end()) {
    //                 instr->replace_all_use_with(*common_exp);
    //                 replace_map[instr] = *common_exp;
    //                 delete_list.insert(instr);
    //             }
    //         }
    //     }
    // }
    // for (auto inst : delete_list){
    //     auto common_exp = replace_map[inst];
    //     while (replace_map.find(common_exp) != replace_map.end())
    //         common_exp = replace_map[common_exp];
    //     inst->replace_all_use_with(common_exp);
    //     inst->get_parent()->delete_instr(inst);
    // }
}