cluster cl;
void init(){}

int main(){
    color c;
    color c2;
    c = #0,0,255#;
    cl = $ 50, 50, 100, 100, 0, 0, c $ ;
    c2 = #0, 255, 0#;
    setFPS(10);
    startGame(640, 480, c2);
    print(1);
    return 0;
}

void update(int f){
    cl.x = random(640);
    cl.y = random(480);

    if(f == 60){
        quit();
    }
}
