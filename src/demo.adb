with Ada.Text_IO;
with Interfaces.C.Strings;
with SDL.Events.Events;
with SDL.Events.Keyboards;
with SDL.Hints;
with SDL.Video.Palettes;
with SDL.Video.Windows.Makers;
with SDL.Video.Renderers.Makers;
with Nuklear;
with SDL.Nuklear.Renderer;

procedure Demo is
   package IO renames Ada.Text_IO;
   package C renames Interfaces.C;
   package Nk renames Nuklear;
   package NkR renames SDL.Nuklear.Renderer;

   use SDL;
   use type SDL.Dimension;
   use type Video.Windows.Window_Flags;
   use type Video.Renderers.Renderer_Flags;

   Window     : Video.Windows.Window;
   Renderer   : Video.Renderers.Renderer;
   Font_Scale : Float;
   Finished   : Boolean := False;
begin
   Hints.Set (Hints.Video_High_DPI_Disabled, "0");

   if Initialise (Enable_Video) then
      Video.Windows.Makers.Create
        (Window,
         "ANuklear: Demo",
         Natural_Coordinates'(others => Video.Windows.Centered_Window_Position),
         Positive_Sizes'(1200, 800),
         Video.Windows.Shown or Video.Windows.Allow_High_DPI);
   end if;

   Video.Renderers.Makers.Create (Renderer, Window, Video.Renderers.Accelerated or Video.Renderers.Present_V_Sync);

   declare
      Renderer_Size :          Natural_Sizes := Zero_Size;
      Window_Size   : constant Natural_Sizes := Window.Get_Size;
      Scale_Size    :          Natural_Sizes;
   begin
      Renderer.Get_Output_Size (Renderer_Size.Width, Renderer_Size.Height);

      Scale_Size.Width  := Renderer_Size.Width / Window_Size.Width;
      Scale_Size.Height := Renderer_Size.Height / Window_Size.Height;

      Renderer.Set_Scale (Float (Scale_Size.Width), Float (Scale_Size.Height));

      Font_Scale := Float (Scale_Size.Height);
   end;

   declare
      Context : access  Nk.nk_context     := NkR.Initialise (Window, Renderer);
      Atlas   : aliased Nk.font_atlas_access := null;
      Config  : aliased Nk.nk_font_config := Nk.font_config (0.0);
      Font    : access  Nk.nk_font        := null;

      package Palettes renames SDL.Video.Palettes;
   begin
      NkR.sdl_font_stash_begin (Atlas'Access);

      --  Font := Nk.font_atlas_add_default (Atlas.all'Access, 13.0 * Font_Scale, Config'Access);
      Font := Nk.font_atlas_add_from_file (Atlas.all'Access, C.To_C ("./Nuklear/extra_font/DroidSans.ttf"), 14.0 * Font_Scale, Config'Access);

      if Font = null then
         IO.Put_Line ("Font didn't work!");
      else
         NkR.sdl_font_stash_end;

         --  this hack makes the font appear to be scaled down to the desired
         --  size and is only necessary when font_scale > 1
         Font.Handle.Height := @ / Font_Scale;

         Nk.style_set_font (Context, Font.Handle'Access);

         --  Nk.set_style ()

         while not Finished loop
            Nk.input_begin (Context);

            declare
               package Events renames SDL.Events.Events;

               use type SDL.Events.Event_Types;
               use type SDL.Events.Keyboards.Key_Codes;

               Event : Events.Events;
            begin
               while Events.Poll (Event) loop
                  case Event.Common.Event_Type is
                     when SDL.Events.Quit =>
                        Finished := True;

                     when  SDL.Events.Keyboards.Key_Down =>
                        if Event.Keyboard.Key_Sym.Key_Code = SDL.Events.Keyboards.Code_Escape then
                           Finished := True;
                        end if;

                     when others =>
                        null;
                  end case;

                  declare
                     Dummy : C.int := NkR.sdl_handle_event (Event);
                  begin
                     null;
                  end;
               end loop;
            end;

            Nk.input_end (Context);

            --  Draw GUI.
            declare
               use type C.unsigned;
               use type Nk.nk_flags;
            begin
               if Nk.start (Context, C.To_C ("Demo"), Nk.nk_rect_t'(50.0, 50.0, 230.0, 250.0),
                 Nk.nk_flags (Nk.Window_Border or Nk.Window_Movable or Nk.Window_Scalable or
                 Nk.Window_Minimizable or Nk.Window_Title))
               then
                  Nk.layout_row_static (Context, Height => 30.0, Item_Width => 80, Cols => 1);

                  if Nk.button_label (Context, C.To_C ("button")) then
                     IO.Put_Line ("Button pressed.");
                  end if;

                  Nk.layout_row_dynamic (Context, Height => 30.0, Cols => 2);
               end if;

               Nk.finish (Context);
            end;

            Renderer.Set_Draw_Colour
              (Palettes.Colour'(Red   => Palettes.Colour_Component (0.10 * 255),
                                Green => Palettes.Colour_Component (0.18 * 255),
                                Blue  => Palettes.Colour_Component (0.24 * 255),
                                Alpha => Palettes.Colour_Component (1.0 * 255)));
            Renderer.Clear;

            NkR.sdl_render (Nk.ANTI_ALIASING_ON);

            Renderer.Present;
         end loop;
      end if;

      nKr.sdl_shutdown;
      Renderer.Finalize;
      Window.Finalize;
      SDL.Quit;
   end;
end Demo;
