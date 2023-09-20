//
//
//# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
//# SPDX-License-Identifier: X11
//
//

#include "experimental/xrt_kernel.h"
#include "experimental/xrt_uuid.h"
#include <iostream>
#include <fstream>
#include <string>
#include <unistd.h>
#include <iomanip>
#include <cstdlib>
#include <time.h>
//#include <openssl/aes.h>
#include <string.h>
#include <thread>
#include <cmath>

// Please use 'xbutil list' command to get the device id of the target alveo card if multiple
//   cards are installed in the system.
#define DEVICE_ID   0

// Kernel krnl_cbc argument id
#define krnl_acc_arg_CFG_CI       0
#define krnl_acc_arg_CFG_CO       1
#define krnl_acc_arg_IFM_ADDR_BASE  2
#define krnl_acc_arg_WGT_ADDR_BASE   3
#define krnl_acc_arg_OFM_ADDR_BASE  4

#define BUF_DEPTH 62
#define OFM_H 62
#define OFM_W 62
#define OFM_C 8

#define TI 16
#define TI_FACTOR 4
#define KERNEL_SIZE 3
#define ACC_ROW 8

#define TI_NUM_IFM 10
#define TI_WIDTH ((TI)+(KERNEL_SIZE)-1)
#define TI_ROW ceil(double(OFM_H)/ACC_ROW)

#define OFM_PORT_WIDTH 32
#define OFM_PORT_CYCLE 16
#define OFM_PORT_BYTE OFM_PORT_WIDTH*OFM_PORT_CYCLE

#define PE_NUM 2

void wait_for_enter(const std::string &msg) {
    std::cout << msg << std::endl;
    std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
}

void wrrite_ofm_validate_test(int* arr, int size){
    for(int i = 0; i < size/4 ;i++){
        std::cout << "idx : " << i << " : " << std::hex << arr[i] << std::endl;
    }
}

// compute time duration
float time_dura(timeval start_time, timeval end_time)
{
    return ((end_time.tv_sec - start_time.tv_sec) * 1000 * 1000 + end_time.tv_usec - start_time.tv_usec) / 1000.0;
}


// function to write binary file
float write_ofm_file(const char *file_name, int ofm_len, int *write_buffer, int groups_num)
{
    std::ofstream file(file_name);

    float re_time = 0;
    struct timeval kernels_start_time, kernels_finish_time; // kernel execution time record
    
    int ofm [OFM_C][OFM_H+4][OFM_W+4];

    int oc, oh, ow, tw, thcnt, th;
    int i;
    gettimeofday(&kernels_start_time, NULL);
    for(int j = 0; j < groups_num; j++){
        oc = 0;
        oh = 0;
        ow = 0;
        tw = 0;
        thcnt = 0;
        th = 0;
        i = 0;
        for(int index = 0; index < ofm_len/4; index+=16) {
            if(oc == 8) break;
//            std::cout <<"test " << index << "  " << oc << "  " << oh << "  " << ow << "  "<< tw << "  " << thcnt << std::endl;
            

            for(int i = 0; i < 8; i++){
                // ofm[oc][oh][i + tw*TI] = write_buffer[ofm_len/4*j + index + i];
                // ofm[oc+1][oh][i + tw*TI] = write_buffer[ofm_len/4*j + index + i+8];
                ofm[oc][i + th][ow] = write_buffer[ofm_len/4*j + index + i+8];
                ofm[oc+1][i + th][ow] = write_buffer[ofm_len/4*j + index + i];
            }

            ow = ow + 1;
                if (ow == 64){
                    ow = 0;
                    th = th+8;
                }
                if(th == 64){
                    th = 0;
                    oc = oc + 2;

                }

            
            // oh = oh + 1;
            // thcnt = thcnt + 1;
            // if (thcnt == 5){
            //     thcnt = 0;
            //     tw = tw + 1;
            //     oh = oh - 5;
            //     if (tw == 4){
            //         tw = 0;
            //         oh = oh + 5;
            //     }
            // }
            // if (oh == 65) {
            //     oh = 0;
            //     oc = oc + 1;
            // }
        }
        gettimeofday(&kernels_finish_time, NULL);
        re_time += time_dura(kernels_start_time, kernels_finish_time); 

        std::cout << "re_arranged successful" << std::endl;
        for (int toc=0; toc < OFM_C; toc++) {
            file << "\n\n";
            for (int toh=0; toh < OFM_H; toh++){
                for (int tow=0; tow < OFM_W; tow++){
                    file << ofm[toc][toh][tow] << " ";
                    if(tow == OFM_W-1){
                        file << "\n";
                    }
                }
            }
        }
    }

    file.close();

    return re_time;
}

// function to ofm int array
void write_bin_file(const char *file_name, int file_size, char *write_buffer)
{
    std::ofstream output_file(file_name, std::ios::out | std::ios::binary);
    output_file.write(write_buffer, file_size);
    output_file.close();
}

// function to read binary file
void read_bin_file(const char *file_name, int file_size, char *read_buffer)
{
    std::ifstream input_file(file_name, std::ios::in | std::ios::binary);
    input_file.read(read_buffer, file_size);
    input_file.close();
}

// compare byte data of two arrays
int data_compare (char *out_data, char *ref_data, int byte_num) {
    int err_num = 0;
    for (int i = 0; i < byte_num; i++) {
        if (out_data[i] != ref_data[i]) {
            printf("  MISMATCH at BYTE %d : EXP = %02x, ACT = %02x\n",i, (unsigned char)ref_data[i], (unsigned char)out_data[i]);
                err_num++;
        }else{
            //printf("  !MATCH at BYTE %d : EXP = %02x, ACT = %02x\n",i, (unsigned char)ref_data[i], (unsigned char)out_data[i]);
        }
    }
    return err_num;
}

void print_help(void) {
    std::cout << std::endl << "    Usage: host_krnl_cbc_test [-g GROUP_NUM] [-w WORD_NUM] [-k KEY] [-v IV] [-v LOOP_NUM] [-s] [-h]" << std::endl;
    std::cout << "      Use -s to emulate ap_ctrl_hs mode, namely wait for ap_done before new ap_start is issued" << std::endl;
    std::cout << "      GROUP_NUM : data group or packet number to be processed, less than 256, default 256" << std::endl;
    std::cout << "      WORD_NUM  : 128-bit word number per group (packet), default 256, should be times of 16" << std::endl;
    std::cout << "      KEY       : 256-bit AES KEY" << std::endl;
    std::cout << "      IV        : 128-bit initial vector for CBC mode" << std::endl;
}


void conv2d_thread(xrt::run run_krnl_acc, xrt::bo ifm_buffer, xrt::bo wgt_buffer, xrt::bo ofm_buffer, int ci, int co) {
    run_krnl_acc.set_arg(krnl_acc_arg_CFG_CI, ci);
    run_krnl_acc.set_arg(krnl_acc_arg_CFG_CO, co);
    run_krnl_acc.set_arg(krnl_acc_arg_IFM_ADDR_BASE, ifm_buffer);
    run_krnl_acc.set_arg(krnl_acc_arg_WGT_ADDR_BASE, wgt_buffer);
    run_krnl_acc.set_arg(krnl_acc_arg_OFM_ADDR_BASE, ofm_buffer);
//    std::cout << "all arg set" <<std::endl;
    run_krnl_acc.start();
    run_krnl_acc.wait();
}

// call kernel with multi-threading
float conv2d(xrt::kernel kernel,                     // kernel handle
                        std::vector<xrt::bo> ifm_sub_buffer,  // ifm buffer array
                        std::vector<xrt::bo> wgt_sub_buffer, //  wgt buffer array
                        std::vector<xrt::bo> ofm_sub_buffer, //  ofm buffer array
                        int groups_num,                          // groups number
                        int ctrl_mode,                           // 0 - ap_ctrl_hs; 1 - ap_ctrl_chain
                        int ci,                     // input channel = 8 * (ci + 1)
                        int co)                     // output channel = 8 * (co + 1)
{
    struct timeval kernels_start_time, kernels_finish_time; // kernel execution time record

    int thread_num = groups_num;    // thread number used to handle all data
//    std::cout << "conv2d called " << std::endl;
    std::vector<xrt::run> run_krnl_acc;
    std::vector<std::thread> t(thread_num);
    
    for (int i = 0; i < thread_num; i++)
    {
        run_krnl_acc.push_back(xrt::run(kernel));
    }

    gettimeofday(&kernels_start_time, NULL);

    if (ctrl_mode) // ap_ctrl_chain running mode
    {
        int residue = groups_num % thread_num;
        int i, k;
        for (k = 0; k < groups_num / thread_num; k++)
        {
            for (i = 0; i < thread_num; i++)
            {
                t[i] = std::thread(conv2d_thread, run_krnl_acc[i], ifm_sub_buffer[k * thread_num + i], wgt_sub_buffer[k * thread_num + i], ofm_sub_buffer[k * thread_num + i],
                             ci, co);
            }
            for (i = 0; i < thread_num; i++)
            {
                t[i].join();
            }
        }
        for (i = 0; i < residue; i++)
        {
            //run_krnl_cbc[i].set_arg(krnl_cbc_arg_SRC_ADDR, input_sub_buffer[k * thread_num + i]);   // use sub-buffer for source pointer argument
            //run_krnl_cbc[i].set_arg(krnl_cbc_arg_DEST_ADDR, output_sub_buffer[k * thread_num + i]); // use sub-buffer for source pointer argument
            t[i] = std::thread(conv2d_thread, run_krnl_acc[i], ifm_sub_buffer[k * thread_num + i], wgt_sub_buffer[k * thread_num + i], ofm_sub_buffer[k * thread_num + i], 
                            ci, co);
        }
        for (i = 0; i < residue; i++)
        {
            t[i].join();
        }
    }
    else // emulate ap_ctrl_hs running mode
    {
        for (int i = 0; i < groups_num; i++) {
            conv2d_thread(run_krnl_acc[0], ifm_sub_buffer[i], wgt_sub_buffer[i], ofm_sub_buffer[i], ci, co);
        }
    }

    gettimeofday(&kernels_finish_time, NULL);
    
    return time_dura(kernels_start_time, kernels_finish_time);  
}



// Main program body
int main(int argc, char *argv[]) {

    int opt;
    const char *optstring = "g:i:o:sh";

    int groups_num = 1; 
    int cfg_ci = 0;
    int cfg_co = 0;

    int chain = 1;      // 0 means ap_ctrl_hs mode, 1 mean ap_ctrl_chain mode

    while ((opt = getopt(argc, argv, optstring)) != -1) {
        if ((opt == 'g') && optarg) {
            groups_num = std::stoi(std::string(optarg));
        }

        if ((opt == 'i') && optarg) {
            cfg_ci = std::stoi(std::string(optarg));
        }

        if ((opt == 'o') && optarg) {
            cfg_co = std::stoi(std::string(optarg));
        }

        if (opt == 's') {
            chain = 0;
        }

        if (opt == 'h') {
            print_help();
            return EXIT_SUCCESS;
        }
    }

    std::cout << std::endl;
    std::cout << "------------------------ krnl_acc test program ------------------------" << std::endl;
    std::cout << "          input channel # : " << cfg_ci << std::endl;
    std::cout << "          output channel # : " << cfg_co << std::endl;
    std::cout << "          input groups number : " << groups_num << std::endl;
    if (chain) {
        std::cout << "               run mode : ap_ctrl_chain" << std::endl;
    } else {
        std::cout << "               run mode : ap_ctrl_hs" << std::endl;
    }

// --------------------------------------------------------------------------------------
// Generate and read plain/cipher data into host buffer
// --------------------------------------------------------------------------------------
    char *ifm, *wgt;
    int ci, co;
    ci = 8*(cfg_ci + 1);
    co = 8*(cfg_co + 1);

    // int ifm_len = ci * (TI+3) * TI_FACTOR * 13 * 8;
    // int wgt_len = 4*4* ci* co* 13* TI_FACTOR;
    // int ofm_len = 4 * 13 * co * 64 * 5;
    std::cout << ci * TI_WIDTH * TI_FACTOR << std::endl;
    int ifm_len = ci * TI_WIDTH * TI_FACTOR * TI_ROW * TI_NUM_IFM;
    int wgt_len = KERNEL_SIZE * KERNEL_SIZE * ci * co * TI_ROW * TI_FACTOR;
    int ofm_len = TI_FACTOR * TI_ROW * co * OFM_PORT_BYTE;

    std::cout << "      ifm size : " << ifm_len * groups_num << std::endl;
    std::cout << "      wgt size : " << wgt_len * groups_num << std::endl;
    std::cout << "      ofm size : " << ofm_len * groups_num << std::endl;


    ifm  = new char [ifm_len * groups_num];
    wgt = new char [wgt_len * groups_num];
    int *ofm = new int [ofm_len/4 * groups_num];

    read_bin_file("./data/ifm.dat",ifm_len * groups_num, ifm);
    read_bin_file("./data/wgt.dat",wgt_len * groups_num, wgt);


// --------------------------------------------------------------------------------------
// Device and kernel initialization
// --------------------------------------------------------------------------------------
    // Judge emulation mode accoring to env variable
    std::string xclbin_file;
    char *env_emu;
    if (env_emu = getenv("XCL_EMULATION_MODE")) {
        std::string mode(env_emu);
        if (mode == "hw_emu")
        {
            std::cout << "Program running in hardware emulation mode" << std::endl;
            xclbin_file = "krnl_acc_test_hw_emu.xclbin";
        }
        else
        {
            std::cout << "[ERROR] Unsupported Emulation Mode: " << mode << std::endl;
            return EXIT_FAILURE;
        }
    }
    else {
        std::cout << "Program running in hardware mode" << std::endl;
        xclbin_file = "krnl_acc_test_hw.xclbin";
    }

    // Load xclbin
    std::cout << "Load " << xclbin_file << std::endl;
    xrt::device device = xrt::device(DEVICE_ID);
    xrt::uuid xclbin_uuid = device.load_xclbin(xclbin_file);
   
    // create kernel objects
    std::cout << "Create kernels" << std::endl;
    xrt::kernel kernel_krnl_acc = xrt::kernel(device, xclbin_uuid, 
                                                "krnl_acc",
                                                xrt::kernel::cu_access_mode::exclusive);

    wait_for_enter("\nPress ENTER to continue after setting up ILA trigger...");
    
    // create device buffer objects
    std::cout << "Create input and output device buffers" << std::endl;
    xrt::bo ifm_buffer = xrt::bo (device, ifm_len * groups_num, xrt::bo::flags::normal, kernel_krnl_acc.group_id(krnl_acc_arg_IFM_ADDR_BASE));
    xrt::bo wgt_buffer = xrt::bo (device, wgt_len * groups_num, xrt::bo::flags::normal, kernel_krnl_acc.group_id(krnl_acc_arg_WGT_ADDR_BASE));
    xrt::bo ofm_buffer = xrt::bo (device, ofm_len * groups_num, xrt::bo::flags::normal, kernel_krnl_acc.group_id(krnl_acc_arg_OFM_ADDR_BASE));
    
    // create sub-buffer objects
    std::vector<xrt::bo> ifm_sub_buffer;
    std::vector<xrt::bo> wgt_sub_buffer;
    std::vector<xrt::bo> ofm_sub_buffer;

    for (int i = 0; i < groups_num; i++) {
        ifm_sub_buffer.push_back(xrt::bo(ifm_buffer, ifm_len, ifm_len * i));
        wgt_sub_buffer.push_back(xrt::bo(wgt_buffer, wgt_len, wgt_len * i));
        ofm_sub_buffer.push_back(xrt::bo(ofm_buffer, ofm_len, ofm_len * i));
    }


    float total_run_time = 0;

    int fail_count;

// --------------------------------------------------------------------------------------
// Convolution acceleration test
// --------------------------------------------------------------------------------------
    std::cout << std::endl << "-------------- Convolution acceleration test -------------- " << std::endl;

    // write plain_data into input device buffer
    ifm_buffer.write(ifm);
    ifm_buffer.sync(XCL_BO_SYNC_BO_TO_DEVICE);
    std::cout << "IFM write to global memory successfully" << std::endl;

    wgt_buffer.write(wgt);
    wgt_buffer.sync(XCL_BO_SYNC_BO_TO_DEVICE);
    std::cout << "WGT write to global memory successfully" << std::endl;

    // Run the kernel
    total_run_time = conv2d(kernel_krnl_acc, ifm_sub_buffer, wgt_sub_buffer, ofm_sub_buffer,
                                      groups_num, chain, cfg_ci, cfg_co);

    // Dump result data from output device buffer
    ofm_buffer.sync(XCL_BO_SYNC_BO_FROM_DEVICE);
    ofm_buffer.read(ofm);

    //std::cout << ofm[0] << "  " << ofm[1] << "  " << ofm[2] << "  "<<  ofm[3] << std::endl;
 //   printf("%08x, %08x, %08x, %08x\n",ofm[0], ofm[1], ofm[2], ofm[3]);
    std::cout << "OFM write to global memory successfully" << std::endl;

    // // Data validation
    // fail_count = data_compare((char*)output_data, added_data, words_num * 64 * groups_num);
    // if (fail_count != 0) {
    //     std::cout << "Data validation FAILED, error num = " << fail_count << std::endl;
    // } else {
    //     std::cout << "Data validation SUCCESS" << std::endl;
    // }
    float re_time;
    re_time = write_ofm_file("./data/hw_conv.txt", ofm_len, ofm, groups_num);
    //wrrite_ofm_validate_test(ofm, ofm_len);
    std::cout << "CONVOLUTION OUTPUT GENERATED" << std::endl;
    
    std::cout << "Execution time = " << total_run_time << " ms" << std::endl;
    std::cout << "Re_arrange time = " << re_time << " ms" << std::endl;

    int excution = (64 - 4 + 1) * (64 - 4 + 1); // (64 - 4 + 1) * (64 - 4 + 1) * 16 * 8 * 8 = 61 * 61 KB
    std::cout << "Total # of processing " << excution * groups_num << "KB" << std::endl;
    std::cout << "Throughput = " <<  excution * groups_num / total_run_time * 1000 / 1024 << " MB/s" << std::endl << std::endl;
//    std::cout << "Throughput = " << ifm_len * groups_num / total_run_time * 1000 / (1024 * 1024) << " MB/s" << std::endl << std::endl;

}
