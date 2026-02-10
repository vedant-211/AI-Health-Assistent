import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:medical/pages/detail.dart';
import 'package:medical/pages/ai_symptoms.dart';

import '../models/category.dart';
import '../models/doctor.dart';

class HomePage extends StatefulWidget {
   const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<CategoryModel> categoriesData = CategoryModel.getCategories();
  final List<DoctorModel> doctorsData = DoctorModel.getDoctors();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header(),
            aiAssistantBanner(),
            categories(),
            doctors()
          ],
        ),
      ),
    );
  }

  Widget aiAssistantBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff51A8FF), Color(0xff3D8FD4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff51A8FF).withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SwasthMitra AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Describe your symptoms and get AI guidance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AISymptomsPage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Start Now',
                      style: TextStyle(
                        color: Color(0xff51A8FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.medical_services,
            color: Colors.white.withOpacity(0.8),
            size: 48,
          ),
        ],
      ),
    );
  }

  Column categories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(
            top: 16,
            left: 16
          ),
          child: Text(
            'Categories',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 18
            ),
          ),
        ),
        Container(
          height: 50,
          margin: const EdgeInsets.all(16),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: (){
                  for(var item in categoriesData) {
                    item.isSelected = false;
                  }
                  categoriesData[index].isSelected = true;
                  setState(() {});
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: categoriesData[index].isSelected ? 
                         const Color(0xff51A8FF).withOpacity(0.45):
                         const Color(0xff050618).withOpacity(0.05),
                        offset: const Offset(0, 4),
                        blurRadius: 25
                      )
                    ],
                    color: categoriesData[index].isSelected ?
                     const Color(0xff51A8FF) : Colors.white
                  ),
                  child: SvgPicture.asset(
                    categoriesData[index].vector,
                    fit: BoxFit.none,
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 50,) ,
            itemCount: categoriesData.length
          ),
        )
      ],
    );
  }

  Container header() {
    return Container(
      color: const Color(0xff51A8FF),
      width: double.infinity,
      height: 350,
      padding: const EdgeInsets.all(16), 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
               'Hi Edi',
               style: TextStyle(
                fontSize: 18,
                color: Color(0xffFFFFFF)
               ),
              ),
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: SvgPicture.asset(
                  'assets/vectors/notification.svg',
                  fit: BoxFit.none,
                ),
              )
            ],
          ),
          const SizedBox(height: 30,),
          const Text(
            "Let's find\nyour top doctor!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600
            ),
          ),
          const SizedBox(height: 30,),
          const TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(
                Icons.search,
                color: Colors.black,
                size: 25,
              ),
              hintText: 'Search here...',
              hintStyle: TextStyle(
                fontWeight: FontWeight.w300
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(
                  Radius.circular(50)
                )
              )
            ),
          )
        ],
      )
    );
  }
  
  Widget doctors() {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 16),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetailPage(doctorModel: doctorsData[index],),)
            );
          },
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff51A8FF).withOpacity(0.07),
                  offset: const Offset(0, 4),
                  blurRadius: 20
                )
              ]
            ),
            child: Row(
              children: [
                Container(
                  width: 105,
                  decoration: BoxDecoration(
                    color: doctorsData[index].imageBox,
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      alignment: Alignment.bottomCenter,
                      image: AssetImage(doctorsData[index].image)
                    )
                  ) ,
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorsData[index].name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16
                        ),
                      ),
                      Text(
                        doctorsData[index].specialties.first,
                        style: const TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 12
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 18,
                          ),
                         const SizedBox(width: 5,),
                          Text(
                            doctorsData[index].score.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w300,
                              fontSize: 12
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 15,),
      itemCount: doctorsData.length
    );
  }
}